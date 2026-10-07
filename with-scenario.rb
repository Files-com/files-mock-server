#!/usr/bin/env ruby
# frozen_string_literal: true

# Runs one consumer command (an SDK or CLI test) against one freshly started
# simulation server loaded with one scenario, then exports the journal and
# stops the server, whether or not the consumer passed.
#
#   ruby with-scenario.rb --scenario NAME_OR_PATH --out DIR [--run-id ID]
#     [--schema-sha256 HEX] [--startup-timeout S] [--consumer-timeout S]
#     [--settle-timeout S] -- COMMAND [ARGS...]
#
# NAME means scenarios/NAME.json beside this script; an argument containing
# "/" or ".json" is a path. A scenario is a JSON object with a string "name",
# an object "reset" (the body sent to POST /__files_mock/v1/reset) and,
# optionally, "journal_checks": ["folders.list cursor chain"], which also
# needs a string "parent" (the listed folder's path).
#
# The server binds 127.0.0.1 only, on a free port, and must report the
# expected schema SHA-256 (--schema-sha256, else FILES_MOCK_SCHEMA_SHA256,
# else lib/simulation/generation.json). The launcher chooses a random instance
# for each run and gives it only to the server, as FILES_MOCK_INSTANCE in the
# server's environment; readiness counts only when it reports that instance
# and the server process is still running. Anything else answering readiness
# on the port is a setup error (3): nothing is reset and no consumer runs.
# The instance recognizes the server; it is not a secret from processes of
# the same user, and the simulator still accepts any credential.
#
# COMMAND runs without a shell, with stdin from /dev/null and the caller's
# environment plus:
#
#   FILES_MOCK_SERVER_URL     http://127.0.0.1:PORT
#   FILES_MOCK_SERVER_HOST    127.0.0.1
#   FILES_MOCK_SERVER_PORT    PORT
#   FILES_MOCK_SCHEMA_SHA256  the schema SHA-256 the server reported
#   FILES_MOCK_INSTANCE       the server's instance, the one this run chose
#   FILES_MOCK_RUN_ID         --run-id, or a UTC timestamp and random suffix
#   FILES_MOCK_API_KEY        filesmock and RUN_ID's letters and digits, a
#                             synthetic key of letters and digits only
#   FILES_MOCK_SCENARIO       the scenario's name
#   FILES_MOCK_SCENARIO_FILE  the scenario's absolute path
#   FILES_MOCK_OUT            DIR, absolute
#
# The simulator accepts any credential; consumers send only
# FILES_MOCK_API_KEY, and only to FILES_MOCK_SERVER_URL.
#
# DIR must not already hold a journal.json. It receives server.log,
# ready.json, reset.json, journal.json and run.json.
#
# Exit status:
#   0  the consumer passed, the journal is complete and requested checks passed
#   2  usage error
#   3  the server did not start, was not the expected one (such as another
#      service answering its port) or refused the reset; the consumer did
#      not run
#   4  the consumer passed, but the journal is missing evidence or a
#      requested journal check failed
#   5  everything else passed, but the server's or the consumer's process
#      group was not known to be empty after TERM and KILL
#   N  the consumer's own nonzero status (124 when it timed out, 128+signo
#      when a signal ended it)
#
# Whatever happens once the server is ready (the consumer passing, failing or
# timing out, an error, or INT, TERM or HUP), the launcher stops what is left
# of the consumer's process group, saves the journal, then stops the server's
# process group, each within the settle timeout, and writes run.json. A signal
# that interrupted it still ends it as that signal, after this cleanup.

require "fileutils"
require "json"
require "net/http"
require "optparse"
require "securerandom"
require "socket"

# One scenario run: a fresh loopback simulation server, one reset, one
# consumer command, the journal, and a run record in the output directory.
class ScenarioRun
  MOCK_DIR = File.expand_path(__dir__)
  HOST = "127.0.0.1"
  CONTRACT_VERSION = 3
  CURSOR_CHAIN = "folders.list cursor chain"
  KNOWN_CHECKS = [ CURSOR_CHAIN ].freeze
  RUN_ID = /\A[A-Za-z0-9._-]{1,64}\z/
  SHA256 = /\A[0-9a-f]{64}\z/
  SIGNALS = %w[INT TERM HUP].freeze
  # Unsetting RUBYOPT and the Bundler variables keeps a caller's own bundle
  # (such as `bundle exec` in the generator checkout) out of the mock's.
  SERVER_ENV = {
    "FILES_MOCK_MODE" => "simulation", "BUNDLE_GEMFILE" => File.join(MOCK_DIR, "Gemfile"),
    "RUBYOPT" => nil, "BUNDLER_SETUP" => nil, "BUNDLE_BIN_PATH" => nil, "BUNDLER_VERSION" => nil
  }.freeze
  USAGE = "usage: ruby with-scenario.rb --scenario NAME_OR_PATH --out DIR [--run-id ID] [--schema-sha256 HEX]\n         " \
          "[--startup-timeout S] [--consumer-timeout S] [--settle-timeout S] -- COMMAND [ARGS...]"

  class UsageError < StandardError; end
  class SetupError < StandardError; end

  def self.parse(argv)
    split = argv.index("--") or raise UsageError, "missing -- COMMAND"
    opts = { command: argv[(split + 1)..], startup: 60, consumer: 900, settle: 15 }
    raise UsageError, "missing COMMAND after --" if opts[:command].empty?

    parser = OptionParser.new(USAGE) do |o|
      o.on("--scenario NAME_OR_PATH") { |v| opts[:scenario] = v }
      o.on("--out DIR") { |v| opts[:out] = v }
      o.on("--run-id ID") { |v| opts[:run_id] = v }
      o.on("--schema-sha256 HEX") { |v| opts[:schema] = v }
      o.on("--startup-timeout S", Integer) { |v| opts[:startup] = v }
      o.on("--consumer-timeout S", Integer) { |v| opts[:consumer] = v }
      o.on("--settle-timeout S", Integer) { |v| opts[:settle] = v }
    end
    rest = parser.parse(argv[0...split])
    raise UsageError, "unexpected arguments before --: #{rest.join(' ')}" unless rest.empty?
    raise UsageError, "--scenario is required" unless opts[:scenario]
    raise UsageError, "--out is required" unless opts[:out]

    %i[startup consumer settle].each do |key|
      raise UsageError, "--#{key}-timeout must be a positive number of seconds" unless opts[key].positive?
    end
    opts
  rescue OptionParser::ParseError => e
    raise UsageError, e.message
  end

  def initialize(opts)
    @opts = opts
    @command = opts[:command]
    @scenario_file = scenario_path(opts[:scenario])
    @scenario = load_scenario(@scenario_file)
    @requested = requested_checks(@scenario)
    # A requested check fails unless it runs and passes.
    @checks = KNOWN_CHECKS.to_h { |name| [ name, @requested.include?(name) ? "failed" : "not requested" ] }
    @run_id = opts[:run_id] || "#{Time.now.utc.strftime('%Y%m%dT%H%M%SZ')}-#{SecureRandom.hex(4)}"
    raise UsageError, "--run-id must match #{RUN_ID.source}" unless @run_id.match?(RUN_ID)

    @api_key = "filesmock#{@run_id.delete('^A-Za-z0-9')}"
    @schema = expected_schema(opts[:schema])
    @out = prepare_out(opts[:out])
    @missing = []
  end

  def run
    @started_at = utc_now
    @leaders = {} # process group ID => its leader, our child, until the leader is reaped
    @unsettled = []
    SIGNALS.each { |sig| trap(sig) { raise(sig == "INT" ? Interrupt : SignalException.new(sig)) } }
    begin
      start_server
      @ready = wait_ready
      reset
      run_consumer
    rescue SetupError => e
      @setup_error = e.message
      say(e.message)
    rescue SignalException, StandardError => e
      @interrupted = e.is_a?(SignalException) ? "SIG#{Signal.signame(e.signo)}" : "#{e.class}: #{e.message}"
      say("stopped by #{@interrupted}; cleaning up")
      raise
    ensure
      SIGNALS.each { |sig| trap(sig, "IGNORE") }
      finish
    end
    exit_status
  end

  private

  def scenario_path(arg)
    return File.join(MOCK_DIR, "scenarios", "#{arg}.json") unless arg.include?("/") || arg.include?(".json")

    File.expand_path(arg)
  end

  def load_scenario(path)
    scenario = JSON.parse(File.read(path))
    return scenario if scenario.is_a?(Hash) && scenario["name"].is_a?(String) && scenario["reset"].is_a?(Hash)

    raise UsageError, "#{path} is not a scenario: it needs a string \"name\" and an object \"reset\""
  rescue SystemCallError, JSON::ParserError => e
    raise UsageError, "cannot read scenario #{path}: #{e.message}"
  end

  def requested_checks(scenario)
    checks = scenario.fetch("journal_checks", [])
    raise UsageError, "journal_checks must be a list drawn from #{KNOWN_CHECKS.inspect}" unless checks.is_a?(Array) && (checks - KNOWN_CHECKS).empty?
    raise UsageError, "the #{CURSOR_CHAIN} check needs a string \"parent\"" if checks.include?(CURSOR_CHAIN) && !(scenario["parent"].is_a?(String) && !scenario["parent"].empty?)

    checks
  end

  def expected_schema(flag)
    value = flag || ENV["FILES_MOCK_SCHEMA_SHA256"] || generated_schema
    return value if value.is_a?(String) && value.match?(SHA256)

    raise UsageError, "the expected schema SHA-256 must be 64 lowercase hex characters, not #{value.inspect}"
  end

  def generated_schema
    JSON.parse(File.read(File.join(MOCK_DIR, "lib", "simulation", "generation.json"))).fetch("schema_sha256")
  rescue SystemCallError, JSON::ParserError, KeyError, TypeError => e
    raise UsageError, "cannot read schema_sha256 from lib/simulation/generation.json: #{e.message}"
  end

  def prepare_out(dir)
    out = File.expand_path(dir)
    FileUtils.mkdir_p(out)
    raise UsageError, "#{out} already holds a journal.json; choose a new --out" if File.exist?(File.join(out, "journal.json"))

    out
  rescue SystemCallError => e
    raise UsageError, "cannot use --out #{dir}: #{e.message}"
  end

  # Asks the kernel for a free loopback port; the server binds it moments later. Another process may
  # bind it first, so readiness is accepted only from this run's instance (#check_ready).
  def free_port
    probe = TCPServer.new(HOST, 0)
    probe.addr[1]
  ensure
    probe&.close
  end

  def start_server
    @port = free_port
    @url = "http://#{HOST}:#{@port}"
    # This run's instance, given only to the server until it is ready.
    @instance = SecureRandom.hex(6)
    say("starting the simulation server on #{HOST}:#{@port}")
    @server_pid = Process.spawn(SERVER_ENV.merge("FILES_MOCK_INSTANCE" => @instance),
                                "bundle", "exec", "puma", "-b", "tcp://#{HOST}:#{@port}",
                                chdir: MOCK_DIR, pgroup: true, in: File::NULL,
                                [ :out, :err ] => [ log_path, "a" ]
    )
    @server_pgid = own_group(@server_pid)
  rescue SystemCallError => e
    raise SetupError, "could not start the server: #{e.message}"
  end

  # Polls readiness until this run's server answers it. Our child must still be running before each
  # attempt and after an answer from its instance; the first 200 answer that is not from it ends the
  # wait as a setup error, so nothing is reset or run against another service on the port.
  def wait_ready
    deadline = clock + @opts[:startup]
    loop do
      check_server
      raise SetupError, "the server was not ready within #{@opts[:startup]} s; see #{log_path}" if clock >= deadline

      response = request("/__files_mock/v1/ready", read_timeout: 2)
      if response&.code == "200"
        ready = check_ready(response.body)
        check_server
        return ready
      end
      sleep 0.2
    end
  end

  # Raises the setup error once the server, our child, has exited; it is then reaped.
  def check_server
    status = wait_for(@server_pid, 0) or return
    @server_pid = nil
    raise SetupError, "the server exited with status #{exit_code(status)} before it was ready; see #{log_path}"
  end

  def check_ready(body)
    write("ready.json", body)
    ready = parse_object(body) or raise SetupError, "readiness on #{@url} did not answer a JSON object"
    wanted = { "status" => "ready", "mode" => "simulation", "contract_version" => CONTRACT_VERSION,
               "schema_sha256" => @schema, "instance" => @instance }
    differences = wanted.filter_map do |key, value|
      next if ready[key] == value
      # Not naming the instance this run expects: it goes to no one but the server until it is ready.
      next "instance #{ready[key].inspect} is not this run's" if key == "instance"

      "#{key} expected #{value.inspect}, reported #{ready[key].inspect}"
    end
    raise SetupError, "readiness on #{@url} was not answered by this run's server: #{differences.join('; ')}" unless differences.empty?

    say("server #{ready['instance']} ready at #{@url}")
    ready
  end

  def reset
    response = request("/__files_mock/v1/reset", body: JSON.generate(@scenario["reset"]))
    raise SetupError, "reset got no response: #{@request_error}" unless response

    write("reset.json", response.body)
    raise SetupError, "reset answered #{response.code}: #{response.body.to_s[0, 500]}" unless response.code == "200"

    say("scenario #{@scenario['name']} loaded (epoch #{parse_object(response.body)&.fetch('epoch', nil).inspect})")
  end

  # Runs the consumer in a process group of its own. Its outcome is its leader's: the exit status, or
  # 124 when it is still running at the deadline. Whatever is left of the group afterwards, descendants
  # included, is stopped in #finish.
  def run_consumer
    @timed_out = false
    pid = Process.spawn(consumer_env, [ @command[0], @command[0] ], *@command[1..], pgroup: true, in: File::NULL)
    @consumer_pgid = own_group(pid)
    status = wait_for(pid, @opts[:consumer])
    if status
      @consumer_status = exit_code(status)
    else
      say("the consumer did not finish within #{@opts[:consumer]} s; stopping it")
      @timed_out = true
      @consumer_status = 124
    end
    say("consumer exited with status #{@consumer_status}")
  rescue SystemCallError => e
    say("could not run #{@command[0]}: #{e.message}")
    @consumer_status = 127
  end

  # Cleanup for every outcome: what is left of the consumer's process group, then the journal while the
  # server still answers, then the server's process group, then run.json. Each step is bounded, and a
  # step that fails is recorded without changing the run's own outcome.
  def finish
    settle("consumer", @consumer_pgid) if @consumer_pgid
    best_effort("the journal") { export_journal } if @ready
    settle("server", @server_pgid) if @server_pgid
    best_effort("run.json") { write_run_record }
  end

  def best_effort(what)
    yield
  rescue StandardError => e
    missing("#{what} could not be saved: #{e.class}: #{e.message}")
  end

  # Remembers a spawned child as the leader of its own process group, which has the child's ID.
  def own_group(pid)
    @leaders[pid] = pid
    pid
  end

  # Stops every process left in an owned process group: TERM, up to the settle timeout, then KILL and up
  # to the settle timeout again. The group is found by its ID, so descendants are stopped even after its
  # leader has exited and been reaped; no other process is signalled. A group still running after KILL
  # is recorded as unsettled.
  def settle(name, pgid)
    %w[TERM KILL].each do |signal|
      return nil if group_gone?(pgid)

      say("stopping what is left of the #{name}'s process group with #{signal}")
      signal_group(pgid, signal)
      deadline = clock + @opts[:settle]
      sleep 0.1 until group_gone?(pgid) || clock >= deadline
    end
    return if group_gone?(pgid)

    @unsettled << name
    say("the #{name}'s process group #{pgid} was still running after TERM and KILL")
  end

  # Whether the group is known to have no process left: only ESRCH says so. Its leader, our child, is
  # reaped once it has exited, so its own exit is not mistaken for a running process.
  def group_gone?(pgid)
    reap(pgid)
    Process.kill(0, -pgid)
    false
  rescue Errno::ESRCH
    true
  rescue Errno::EPERM
    # The probe was refused, which does not show that the group is gone: settle keeps waiting until
    # its deadline and then records the group as unsettled.
    false
  end

  def reap(pgid)
    leader = @leaders[pgid] or return
    _, status = Process.wait2(leader, Process::WNOHANG)
    @leaders.delete(pgid) if status
  rescue Errno::ECHILD
    @leaders.delete(pgid)
  end

  def consumer_env
    {
      "FILES_MOCK_SERVER_URL" => @url, "FILES_MOCK_SERVER_HOST" => HOST, "FILES_MOCK_SERVER_PORT" => @port.to_s,
      "FILES_MOCK_SCHEMA_SHA256" => @schema, "FILES_MOCK_INSTANCE" => @ready["instance"].to_s,
      "FILES_MOCK_RUN_ID" => @run_id, "FILES_MOCK_API_KEY" => @api_key,
      "FILES_MOCK_SCENARIO" => @scenario["name"], "FILES_MOCK_SCENARIO_FILE" => @scenario_file,
      "FILES_MOCK_OUT" => @out
    }
  end

  # Saves the journal exactly as served; anything short of a complete one is
  # missing evidence.
  def export_journal
    response = request("/__files_mock/v1/journal")
    return missing("could not read the journal: #{@request_error}") unless response
    return missing("the journal answered #{response.code}") unless response.code == "200"

    write("journal.json", response.body)
    @journal = { "file" => "journal.json", "complete" => nil, "dropped" => nil, "entries" => nil }
    journal = parse_object(response.body) or return missing("the journal is not a JSON object")
    entries = journal["entries"]
    @journal.merge!("complete" => journal["complete"], "dropped" => journal["dropped"],
                    "entries" => entries.is_a?(Array) ? entries.length : nil
    )
    say("journal: #{@journal['entries'].inspect} entries, complete #{journal['complete'].inspect}, " \
        "dropped #{journal['dropped'].inspect}"
       )
    return missing("the journal has no entries list") unless entries.is_a?(Array)

    missing("the journal is incomplete") unless journal["complete"] == true && journal["dropped"] == 0
    run_checks(entries)
  end

  def run_checks(entries)
    return unless @requested.include?(CURSOR_CHAIN)

    problems = cursor_chain_problems(entries)
    problems.each { |problem| say("#{CURSOR_CHAIN}: #{problem}") }
    @checks[CURSOR_CHAIN] = problems.empty? ? "passed" : "failed"
    missing("the #{CURSOR_CHAIN} check failed") unless problems.empty?
  end

  # Checks only what the server saw of the parent's listings, in order: each traversal starts without
  # a cursor, continues with exactly the cursor the page before it returned and ends at a page that
  # returns none, and a new traversal starts only after the one before it ended. Several complete
  # traversals pass. The consumer checks its own results.
  def cursor_chain_problems(entries)
    path = "/api/rest/v1/folders/#{@scenario['parent']}"
    pages = entries.select { |e| e.is_a?(Hash) && e["operation"] == "folders.list" && e["path"] == path }
    return [ "no folders.list requests for #{path}" ] if pages.empty?

    problems = []
    expected = nil # the cursor the open traversal must send next; nil when none is open
    pages.each do |page|
      seq = page["seq"].inspect
      sent = page["cursor_sha256"]
      if sent.nil?
        problems << "seq #{seq} started a traversal before the one before it reached its last page" if expected
      elsif sent != expected
        problems << "seq #{seq} sent a cursor the listing before it did not return"
      end
      if page["status"] == 200
        expected = page["next_cursor_sha256"]
      else
        problems << "seq #{seq} answered status #{page['status'].inspect}"
      end
    end
    problems << "the last traversal did not reach its last page" if expected
    problems
  end

  def signal_group(pgid, signal)
    Process.kill(signal, -pgid)
  rescue Errno::ESRCH, Errno::EPERM
    nil
  end

  # Waits up to +seconds+ for our child +pid+ to exit; returns its status (the child is then reaped and
  # no longer a group's leader to reap), or nil.
  def wait_for(pid, seconds)
    deadline = clock + seconds
    loop do
      _, status = Process.wait2(pid, Process::WNOHANG)
      if status
        @leaders.delete(pid)
        return status
      end
      return nil if clock >= deadline

      sleep 0.1
    end
  end

  # A control request to the server; nil (with @request_error) when none came back.
  def request(path, body: nil, read_timeout: 30)
    http = Net::HTTP.new(HOST, @port, nil) # nil: never an environment proxy
    http.open_timeout = 2
    http.read_timeout = read_timeout
    http.start do |connection|
      body ? connection.post(path, body, "Content-Type" => "application/json") : connection.get(path)
    end
  rescue SystemCallError, IOError, Timeout::Error, Net::HTTPBadResponse, Net::ProtocolError => e
    @request_error = "#{e.class}: #{e.message}"
    nil
  end

  def exit_status
    return 3 if @setup_error
    return @consumer_status unless @consumer_status.zero?
    return 4 unless @missing.empty?

    @unsettled.empty? ? 0 : 5
  end

  def write_run_record
    write("run.json", "#{JSON.pretty_generate(
      "format" => "files-mock-scenario-run/1",
      "scenario" => @scenario["name"], "scenario_file" => @scenario_file,
      "run_id" => @run_id, "api_key" => @api_key,
      "server" => { "url" => @url, "instance" => @ready&.fetch("instance", nil), "schema_sha256" => @schema,
                    "contract_version" => @ready&.fetch("contract_version", nil), "log" => "server.log",
                    "process_group" => @server_pgid },
      "consumer" => { "argv" => @command, "status" => @consumer_status, "timed_out" => @timed_out,
                      "process_group" => @consumer_pgid },
      "journal" => @journal || { "file" => nil, "complete" => nil, "dropped" => nil, "entries" => nil },
      "journal_checks" => @checks,
      "setup_error" => @setup_error, "interrupted" => @interrupted, "missing_evidence" => @missing,
      "unsettled_process_groups" => @unsettled,
      "started_at" => @started_at, "ended_at" => utc_now
    )}\n"
    )
  end

  def missing(message)
    say("missing evidence: #{message}")
    @missing << message
    nil
  end

  def parse_object(body)
    value = JSON.parse(body.to_s)
    value.is_a?(Hash) ? value : nil
  rescue JSON::ParserError
    nil
  end

  def exit_code(status)
    status.exited? ? status.exitstatus : 128 + status.termsig.to_i
  end

  def write(name, body) = File.binwrite(File.join(@out, name), body.to_s)
  def log_path = File.join(@out, "server.log")
  def clock = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  def utc_now = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
  def say(message) = warn("with-scenario: #{message}")
end

begin
  exit ScenarioRun.new(ScenarioRun.parse(ARGV)).run
rescue ScenarioRun::UsageError => e
  warn "with-scenario: #{e.message}"
  warn ScenarioRun::USAGE
  exit 2
end
