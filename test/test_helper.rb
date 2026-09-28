require "io/wait"
require "json"
require "minitest/autorun"
require "net/http"
require "rack/lint"
require "rack/mock_request"
require "socket"
require "tempfile"

APP_ROOT = File.expand_path("..", __dir__)
require File.join(APP_ROOT, "lib/simulation")

# Rack-level requests against simulators built inside the test process.
module SimulationRequests
  Response = Struct.new(:status, :headers, :body) do
    def json
      JSON.parse(body)
    end
  end

  attr_reader :app

  def new_app(**)
    Rack::Lint.new(FilesMockServer::Simulation::App.new(limits: FilesMockServer::Simulation::Limits.new(**)))
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
    response = Rack::MockRequest.new(to).request(method, uri, env.merge(input: body))
    Response.new(response.status, response.headers, response.body)
  end
end

# A real `bundle exec puma` for this app, bound to an ephemeral loopback port.
class ServerProcess
  TIMEOUT = 60
  # Keep the caller's shell settings from changing which server starts.
  CLEAN_ENV = %w[FILES_MOCK_MODE WEB_CONCURRENCY FILES_MOCK_MAX_RECORDS FILES_MOCK_MAX_JOURNAL_ENTRIES FILES_MOCK_MAX_BODY_BYTES].to_h { |name| [ name, nil ] }.freeze

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
    deadline = now + TIMEOUT
    until (listening = output.match(/Listening on (http:\/\/127\.0\.0\.1:\d+)/))
      raise "Puma exited before listening:\n#{output}" if exited?
      raise "Puma did not listen within #{TIMEOUT}s:\n#{output}" if now > deadline

      sleep 0.05
    end
    @url = listening[1]
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

  def request(method, path, body = nil)
    Net::HTTP.start("127.0.0.1", port, nil, open_timeout: 10, read_timeout: 10) do |http|
      http.send_request(method, path, body && JSON.generate(body), body ? { "Content-Type" => "application/json" } : {})
    end
  end

  def json(method, path, body = nil)
    response = request(method, path, body)
    [ response.code.to_i, JSON.parse(response.body) ]
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
