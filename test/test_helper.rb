require "digest"
require "erb"
require "fileutils"
require "io/wait"
require "json"
require "minitest/autorun"
require "net/http"
require "openssl"
require "rack/lint"
require "rack/mock_request"
require "socket"
require "tempfile"
require "time"
require "tmpdir"

APP_ROOT = File.expand_path("..", __dir__)
require File.join(APP_ROOT, "lib/simulation")

# A request body still being received when something else happens, such as a reset.
class InterruptedBody < StringIO
  def initialize(body, on_first_read)
    super(body)
    @on_first_read = on_first_read
  end

  def read(...)
    @on_first_read&.call
    @on_first_read = nil
    super
  end
end

# Rack-level requests against simulators built inside the test process.
module SimulationRequests
  # In-process simulators have no listening socket, so they are given the origin of upload and download URLs.
  ORIGIN = "http://127.0.0.1:4041".freeze

  Response = Struct.new(:status, :headers, :body) do
    def json
      JSON.parse(body)
    end
  end

  attr_reader :app

  def new_app(transfer_origin: ORIGIN, **)
    Rack::Lint.new(FilesMockServer::Simulation::App.new(limits: FilesMockServer::Simulation::Limits.new(**), transfer_origin:))
  end

  # Sends params the way the Go and Python SDKs do: in the query string for GET and DELETE, as a JSON body otherwise.
  def api(method, path, params = nil, to: app)
    uri = "/api/rest/v1#{path}"
    return request(to, method, uri) if params.nil?
    return request(to, method, "#{uri}?#{Rack::Utils.build_nested_query(params)}") if %w[GET DELETE].include?(method)

    request(to, method, uri, JSON.generate(params))
  end

  def control(method, name, body = nil, to: app)
    request(to, method, "/__files_mock/v1/#{name}", body && JSON.generate(body))
  end

  def reset(fixtures = {}, to: app)
    response = control("POST", "reset", { "fixtures" => fixtures }, to:)
    assert_equal 200, response.status, response.body
    response.json
  end

  def add_fault(rule, to: app)
    response = control("POST", "faults", rule, to:)
    assert_equal 201, response.status, response.body
    response.json
  end

  def usernames(to: app)
    api("GET", "/users", to:).json.map { |user| user["username"] }
  end

  def request(to, method, uri, body = nil, env = {})
    env = { "CONTENT_TYPE" => "application/json" }.merge(env) if body
    raw_request(to, method, uri, body, env)
  end

  # Sends raw bytes, or a GET, to an upload or download URL the simulator issued, with no content type as the SDKs do.
  def transfer(method, url, body = nil, env = {}, to: app)
    raw_request(to, method, URI(url).request_uri, body, env)
  end

  def raw_request(to, method, uri, body, env)
    response = Rack::MockRequest.new(to).request(method, uri, env.merge(input: body))
    Response.new(response.status, response.headers, response.body)
  end
end

# Uploads, downloads and journal reads the way the SDKs and tests use them, for a test that
# includes SimulationRequests.
module FileRequests
  # A path as the Go SDK puts it in a URL: each name percent-encoded, the slashes kept.
  def route(path)
    path.split("/", -1).map { |name| ERB::Util.url_encode(name) }.join("/")
  end

  def begin_upload(route, params = {}, to: app)
    response = api("POST", "/file_actions/begin_upload/#{route}", params, to:)
    assert_equal 200, response.status, response.body
    assert_equal 1, response.json.size
    response.json.first
  end

  # Returns the part's ETag without its quotes, as the SDKs list it.
  def put_part(part, bytes)
    response = transfer("PUT", part["upload_uri"], bytes)
    assert_equal 200, response.status, response.body
    response.headers["etag"].delete('"')
  end

  # Uploads parts in order through the protocol the SDKs use and returns the finalize response.
  def upload(path, parts, route: route(path), finalize: {})
    first = begin_upload(route)
    etags = parts.each_with_index.map do |bytes, index|
      part = index.zero? ? first : begin_upload(route, { "ref" => first["ref"], "part" => index + 1 })
      { "etag" => put_part(part, bytes), "part" => index + 1 }
    end
    api("POST", "/files/#{route}", { "action" => "end", "ref" => first["ref"], "etags" => etags }.merge(finalize))
  end

  def download(path, env = {})
    negotiated = api("GET", "/files/#{route(path)}")
    return negotiated unless negotiated.status == 200

    transfer("GET", negotiated.json["download_uri"], nil, env)
  end

  def journal
    control("GET", "journal").json["entries"]
  end

  # The given fields of the journal entries for one operation, oldest first.
  def journaled(operation, fields)
    journal.select { |entry| entry["operation"] == operation }.map { |entry| entry.values_at(*fields) }
  end
end

# A real `bundle exec puma` for this app, bound to an ephemeral loopback port.
class ServerProcess
  TIMEOUT = 60
  # Keep the caller's shell settings from changing which server starts.
  CLEAN_ENV = %w[FILES_MOCK_MODE WEB_CONCURRENCY FILES_MOCK_MAX_RECORDS FILES_MOCK_MAX_JOURNAL_ENTRIES FILES_MOCK_MAX_BODY_BYTES
                 FILES_MOCK_MAX_TRANSFER_BYTES FILES_MOCK_TRANSFER_ORIGIN].to_h { |name| [ name, nil ] }.freeze

  attr_reader :url

  def self.start(env, *)
    server = new(env, *)
    server.wait_until_listening
    server
  rescue StandardError
    server&.stop
    raise
  end

  # Runs a server that is expected to stop by itself and returns [ exit status, output ].
  def self.run_to_exit(env, *)
    server = new(env, *)
    [ server.wait_for_exit, server.output ]
  ensure
    server&.stop
  end

  def initialize(env, *args)
    @output = +""
    @output_lock = Mutex.new
    command = [ "bundle", "exec", "puma", "-b", "tcp://127.0.0.1:0", *args ]
    reader, writer = IO.pipe
    @pid = Process.spawn(CLEAN_ENV.merge(env), *command, chdir: APP_ROOT, in: File::NULL, out: writer, err: writer, pgroup: true)
    writer.close
    @reader = Thread.new do
      reader.each_line { |line| @output_lock.synchronize { @output << line } }
    ensure
      reader.close
    end
  end

  def output
    @output_lock.synchronize { @output.dup }
  end

  def wait_until_listening
    @url = wait_for_output(/Listening on (http:\/\/127\.0\.0\.1:\d+)/)[1]
  end

  # Waits until Puma has printed a line matching pattern and returns the match. Puma prints one
  # "Listening on" line per bind, in order, so a later bind's line can arrive after the first.
  def wait_for_output(pattern)
    deadline = now + TIMEOUT
    until (match = output.match(pattern))
      raise "Puma exited before printing #{pattern.inspect}:\n#{output}" if exited?
      raise "Puma did not print #{pattern.inspect} within #{TIMEOUT}s:\n#{output}" if now > deadline

      sleep 0.05
    end
    match
  end

  def wait_for_exit(timeout = TIMEOUT)
    deadline = now + timeout
    until exited?
      raise "Puma was still running after #{timeout}s:\n#{output}" if now > deadline

      sleep 0.05
    end
    @status
  end

  def exited?
    @status ||= Process.wait2(@pid, Process::WNOHANG)&.last
    !@status.nil?
  end

  def stop
    return if exited?

    signal("TERM")
    begin
      wait_for_exit(15)
    rescue RuntimeError
      signal("KILL")
      wait_for_exit(15)
    end
  ensure
    @reader.join(5)
  end

  def port
    URI(url).port
  end

  def request(method, path, body = nil, headers = {})
    Net::HTTP.start("127.0.0.1", port, nil, open_timeout: 10, read_timeout: 10) do |http|
      http.send_request(method, path, body && JSON.generate(body), (body ? { "Content-Type" => "application/json" } : {}).merge(headers))
    end
  end

  def json(method, path, body = nil, headers = {})
    response = request(method, path, body, headers)
    [ response.code.to_i, JSON.parse(response.body) ]
  end

  # Writes a raw request and returns [ status, headers, body ] once the server closes the connection.
  def raw(request)
    socket = TCPSocket.new("127.0.0.1", port)
    socket.write(request)
    response = +""
    while socket.wait_readable(10) && (chunk = socket.read_nonblock(65_536, exception: false))
      response << chunk unless chunk == :wait_readable
    end
    head, body = response.split("\r\n\r\n", 2)
    status, *fields = head.split("\r\n")
    headers = fields.to_h do |field|
      name, value = field.split(": ", 2)
      [ name.downcase, value ]
    end
    [ status[/\A\S+ (\d{3})/, 1].to_i, headers, body ]
  ensure
    socket&.close
  end

  # Writes raw request parts with a pause between them, so Puma reads each one separately, and
  # returns the response status line. The caller decides whether the request is ever finished.
  def send_in_parts(parts)
    socket = TCPSocket.new("127.0.0.1", port)
    parts.each do |part|
      socket.write(part)
      sleep 0.1
    end
    response = +""
    until response.include?("\r\n")
      raise "no response within 10 seconds" unless socket.wait_readable(10)

      response << socket.readpartial(4096)
    end
    response.lines.first.strip
  ensure
    socket&.close
  end

  private

  # Signals the whole process group, which may already have exited.
  def signal(name)
    Process.kill(name, -@pid)
  rescue Errno::ESRCH
    nil
  end

  def now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
