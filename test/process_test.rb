require_relative "test_helper"

class ProcessTest < Minitest::Test
  FIXTURES = { "fixtures" => { "users" => (1..5).map { |number| { "username" => "user#{number}" } } } }.freeze

  def test_legacy_mode_keeps_example_responses_and_static_route_precedence
    server = ServerProcess.start({})
    list = server.request("GET", "/api/rest/v1/users")
    assert_equal [ "200", "application/json" ], [ list.code, list["content-type"] ]
    example_user = JSON.parse(list.body).first
    assert_equal 1, example_user["id"]
    assert_equal [ 200, example_user ], server.json("GET", "/api/rest/v1/users/1")

    unmatched = server.request("GET", "/api/rest/v1/users/not-an-integer")
    assert_equal [ "404", "404 Not Found" ], [ unmatched.code, unmatched.body ]
    assert_equal [ 400, { "error" => "username is missing" } ], server.json("POST", "/api/rest/v1/users", {})
    assert_equal [ 201, example_user ], server.json("POST", "/api/rest/v1/users", { "username" => "not-stored" })
    assert_equal [ example_user ], JSON.parse(server.request("GET", "/api/rest/v1/users").body)

    # A static route must win over the parameterized /automations/{id} route declared beside it.
    status, authoring_schema = server.json("GET", "/api/rest/v1/automations/authoring_schema")
    assert_equal 200, status
    refute_equal server.json("GET", "/api/rest/v1/automations/1").last, authoring_schema
    assert_equal "404", server.request("GET", "/__files_mock/v1/ready").code
  ensure
    server&.stop
  end

  def test_simulation_process_serves_state_over_http_and_stops_cleanly
    server = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation" })
    status, ready = server.json("GET", "/__files_mock/v1/ready")
    assert_equal [ 200, "simulation" ], [ status, ready["mode"] ]
    assert_equal 200, server.request("POST", "/__files_mock/v1/reset", FIXTURES).code.to_i

    page = server.request("GET", "/api/rest/v1/users?per_page=2")
    page_usernames = JSON.parse(page.body).map { |user| user["username"] }
    assert_equal %w[user1 user2], page_usernames
    refute_nil page["X-Files-Cursor"]
    assert_equal page["X-Files-Cursor"], page["X-Files-Cursor-Next"]
    code, created = server.json("POST", "/api/rest/v1/users", { "username" => "user6" })
    assert_equal [ 201, 6 ], [ code, created["id"] ]

    port = server.port
    server.stop
    assert server.exited?
    assert_raises(Errno::ECONNREFUSED) { TCPSocket.new("127.0.0.1", port).close }
  ensure
    server&.stop
  end

  def test_simultaneous_simulators_with_the_same_fixtures_stay_independent
    first = ServerProcess.new({ "FILES_MOCK_MODE" => "simulation" })
    second = ServerProcess.new({ "FILES_MOCK_MODE" => "simulation" })
    [ first, second ].each(&:wait_until_listening)
    [ first, second ].each { |server| assert_equal 200, server.request("POST", "/__files_mock/v1/reset", FIXTURES).code.to_i }
    refute_equal first.json("GET", "/__files_mock/v1/ready").last["instance"], second.json("GET", "/__files_mock/v1/ready").last["instance"]

    cursor = first.request("GET", "/api/rest/v1/users?per_page=2")["X-Files-Cursor"]
    assert_equal 422, second.request("GET", "/api/rest/v1/users?per_page=2&cursor=#{cursor}").code.to_i
    assert_equal 6, first.json("POST", "/api/rest/v1/users", { "username" => "only-first" }).last["id"]
    assert_equal 201, first.request("POST", "/__files_mock/v1/faults", { "operation" => "users.list", "status" => 503 }).code.to_i

    code, users = second.json("GET", "/api/rest/v1/users")
    assert_equal [ 200, 5 ], [ code, users.size ]
    assert_equal 200, second.request("POST", "/__files_mock/v1/reset", { "fixtures" => {} }).code.to_i
    assert_equal [ 200, [] ], second.json("GET", "/api/rest/v1/users")

    assert_equal 503, first.request("GET", "/api/rest/v1/users").code.to_i
    code, users = first.json("GET", "/api/rest/v1/users")
    assert_equal [ 200, 6 ], [ code, users.size ]
  ensure
    first&.stop
    second&.stop
  end

  def test_puma_refuses_bodies_over_the_limit_before_they_finish
    server = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation", "FILES_MOCK_MAX_BODY_BYTES" => "64" })
    # Neither oversized request is ever finished, so each 413 can only come from Puma stopping at the limit.
    assert_match(/\AHTTP\/1\.1 413 /, server.send_in_parts([ request_head("Content-Length: 1000") ]))
    assert_match(/\AHTTP\/1\.1 413 /, server.send_in_parts([ request_head("Transfer-Encoding: chunked"), chunk("a" * 40), chunk("b" * 40) ]))
    assert_empty server.json("GET", "/__files_mock/v1/journal").last["entries"]

    whole = JSON.generate("username" => "sent-whole")
    assert_match(/\AHTTP\/1\.1 201 /, server.send_in_parts([ request_head("Content-Length: #{whole.bytesize}") + whole ]))
    chunked = JSON.generate("username" => "sent-in-chunks")
    assert_match(/\AHTTP\/1\.1 201 /, server.send_in_parts([ request_head("Transfer-Encoding: chunked"), chunk(chunked[0, 10]), "#{chunk(chunked[10..])}0\r\n\r\n" ]))
    usernames = server.json("GET", "/api/rest/v1/users").last.map { |user| user["username"] }
    assert_equal %w[sent-whole sent-in-chunks], usernames
  ensure
    server&.stop
  end

  def test_invalid_mode_stops_startup_with_a_clear_error
    status, output = ServerProcess.run_to_exit({ "FILES_MOCK_MODE" => "simulate" })
    refute status.success?
    assert_includes output, 'FILES_MOCK_MODE="simulate" is not a valid mode'
    refute_includes output, "Listening on"
  end

  def test_simulation_refuses_to_fork_workers_with_separate_state
    status, output = ServerProcess.run_to_exit({ "FILES_MOCK_MODE" => "simulation" }, "--workers", "2")
    refute status.success?
    assert_includes output, "keeps its state in one process"
  end

  def test_simulation_listens_on_loopback_unless_a_bind_is_given
    assert_equal [ "tcp://127.0.0.1:4041" ], configured_binds("simulation")
    assert_equal [ "tcp://0.0.0.0:4041" ], configured_binds(nil)
  end

  private

  def request_head(framing)
    "POST /api/rest/v1/users HTTP/1.1\r\nHost: 127.0.0.1\r\nContent-Type: application/json\r\nConnection: close\r\n#{framing}\r\n\r\n"
  end

  def chunk(data)
    "#{data.bytesize.to_s(16)}\r\n#{data}\r\n"
  end

  # The binds Puma would use from config/puma.rb when no -b option is given.
  def configured_binds(mode)
    script = 'require "json"; require "puma"; require "puma/configuration"; print JSON.generate(Puma::Configuration.new.clamp[:binds])'
    output = IO.popen(ServerProcess::CLEAN_ENV.merge("FILES_MOCK_MODE" => mode), [ "bundle", "exec", "ruby", "-e", script ], chdir: APP_ROOT, &:read)
    assert Process.last_status.success?, "loading config/puma.rb failed"
    JSON.parse(output)
  end
end
