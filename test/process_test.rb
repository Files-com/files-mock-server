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

  def test_transfers_over_puma_use_the_address_the_request_arrived_on
    server = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation" })
    # The Host header must not choose where clients send and fetch bytes.
    status, parts = server.json("POST", "/api/rest/v1/file_actions/begin_upload/folder/data.bin", {}, "Host" => "attacker.example")
    assert_equal 200, status
    first = parts.first
    assert first["upload_uri"].start_with?("#{server.url}/__files_mock/transfer/upload/")

    # Puma decodes a chunked body before the simulator counts and stores it.
    chunked = server.raw("#{put_head(first["upload_uri"], "Transfer-Encoding: chunked")}#{chunk("\x00\xFFbinary ")}#{chunk("bytes\r\n")}0\r\n\r\n")
    assert_equal [ 200, %("#{Digest::SHA256.hexdigest("\x00\xFFbinary bytes\r\n".b)}") ], [ chunked[0], chunked[1]["etag"] ]
    _status, (second,) = server.json("POST", "/api/rest/v1/file_actions/begin_upload/folder/data.bin", { "ref" => first["ref"], "part" => 2 })
    etag = server.raw("#{put_head(second["upload_uri"], "Content-Length: 4")}tail")[1]["etag"]
    etags = [ { "etag" => chunked[1]["etag"].delete('"'), "part" => 1 }, { "etag" => etag.delete('"'), "part" => 2 } ]
    assert_equal 201, server.json("POST", "/api/rest/v1/files/folder/data.bin", { "action" => "end", "ref" => first["ref"], "etags" => etags }).first

    _status, file = server.json("GET", "/api/rest/v1/files/folder/data.bin", nil, "Host" => "attacker.example")
    assert file["download_uri"].start_with?("#{server.url}/__files_mock/transfer/download/")
    download = URI(file["download_uri"]).request_uri
    assert_equal "\x00\xFFbinary bytes\r\ntail".b, server.request("GET", download).body.b
    ranged = server.request("GET", download, nil, "Range" => "bytes=2-7")
    assert_equal [ "206", "binary", "bytes 2-7/20" ], [ ranged.code, ranged.body, ranged["Content-Range"] ]
    unsatisfiable = server.request("GET", download, nil, "Range" => "bytes=20-")
    assert_equal [ "416", "bytes */20" ], [ unsatisfiable.code, unsatisfiable["Content-Range"] ]
  ensure
    server&.stop
  end

  def test_puma_refuses_part_bodies_over_the_limits_without_holding_them
    server = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation", "FILES_MOCK_MAX_BODY_BYTES" => "64", "FILES_MOCK_MAX_TRANSFER_BYTES" => "100" })
    _status, (part,) = server.json("POST", "/api/rest/v1/file_actions/begin_upload/a.bin", {})
    # Neither oversized body is ever finished, so each 413 can only come from Puma stopping at the limit.
    assert_match(/\AHTTP\/1\.1 413 /, server.send_in_parts([ put_head(part["upload_uri"], "Content-Length: 1000") ]))
    assert_match(/\AHTTP\/1\.1 413 /, server.send_in_parts([ put_head(part["upload_uri"], "Transfer-Encoding: chunked"), chunk("a" * 40), chunk("b" * 40) ]))
    assert_equal([ "files.begin_upload" ], server.json("GET", "/__files_mock/v1/journal").last["entries"].map { |entry| entry["operation"] })
    assert_equal 0, transfer_state(server)["bytes_in_use"]

    # Bodies within the body limit still count toward the transfer limit, which refuses the second one.
    assert_equal 200, server.raw("#{put_head(part["upload_uri"], "Content-Length: 64")}#{"c" * 64}")[0]
    _status, (other,) = server.json("POST", "/api/rest/v1/file_actions/begin_upload/b.bin", {})
    status, _headers, body = server.raw("#{put_head(other["upload_uri"], "Content-Length: 64")}#{"d" * 64}")
    assert_equal [ 409, "simulation/limit-exceeded", 64 ], [ status, JSON.parse(body)["type"], transfer_state(server)["bytes_in_use"] ]
    assert_equal 200, server.request("POST", "/__files_mock/v1/reset", {}).code.to_i
    assert_equal({ "uploads" => 0, "files" => 0, "bytes_in_use" => 0 }, transfer_state(server))
  ensure
    server&.stop
  end

  def test_transfer_origin_setting_is_validated_at_startup_and_used_in_urls
    status, output = ServerProcess.run_to_exit({ "FILES_MOCK_MODE" => "simulation", "FILES_MOCK_TRANSFER_ORIGIN" => "ftp://127.0.0.1:40410" })
    refute status.success?
    assert_includes output, "FILES_MOCK_TRANSFER_ORIGIN"
    refute_includes output, "Listening on"

    server = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation", "FILES_MOCK_TRANSFER_ORIGIN" => "http://127.0.0.1:40410" })
    _status, (part,) = server.json("POST", "/api/rest/v1/file_actions/begin_upload/a.bin", {})
    assert part["upload_uri"].start_with?("http://127.0.0.1:40410/__files_mock/transfer/upload/")
  ensure
    server&.stop
  end

  # with-scenario.rb recognizes the server it started by the instance it gives it, so readiness must report
  # exactly that instance, a server started without one must still choose its own, and a malformed one must
  # stop startup.
  def test_instance_setting_is_validated_at_startup_and_reported_by_readiness
    status, output = ServerProcess.run_to_exit({ "FILES_MOCK_MODE" => "simulation", "FILES_MOCK_INSTANCE" => "5F0C3A9E8D7B" })
    refute status.success?
    assert_includes output, "FILES_MOCK_INSTANCE"
    refute_includes output, "Listening on"

    named = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation", "FILES_MOCK_INSTANCE" => "5f0c3a9e8d7b" })
    unnamed = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation" })
    assert_equal([ 200, "5f0c3a9e8d7b" ], named.json("GET", "/__files_mock/v1/ready").then { |code, ready| [ code, ready["instance"] ] })
    instance = unnamed.json("GET", "/__files_mock/v1/ready").last["instance"]
    assert_match(/\A[0-9a-f]{12}\z/, instance)
    refute_equal "5f0c3a9e8d7b", instance

    # Cursor tokens carry the instance, so a cursor from the named server is still its own.
    [ named, unnamed ].each { |server| assert_equal 200, server.request("POST", "/__files_mock/v1/reset", FIXTURES).code.to_i }
    cursor = named.request("GET", "/api/rest/v1/users?per_page=2")["X-Files-Cursor"]
    refute_nil cursor
    assert_equal 200, named.request("GET", "/api/rest/v1/users?per_page=2&cursor=#{cursor}").code.to_i
    assert_equal 422, unnamed.request("GET", "/api/rest/v1/users?per_page=2&cursor=#{cursor}").code.to_i
  ensure
    named&.stop
    unnamed&.stop
  end

  # Behind a TLS bind, upload and download URLs use https and the address the request arrived on.
  def test_a_tls_bind_issues_https_transfer_urls
    directory = Dir.mktmpdir
    key = OpenSSL::PKey::RSA.new(2048)
    certificate = OpenSSL::X509::Certificate.new
    certificate.version = 2
    certificate.serial = 1
    certificate.subject = certificate.issuer = OpenSSL::X509::Name.parse("/CN=127.0.0.1")
    certificate.public_key = key.public_key
    certificate.not_before = Time.now - 60
    certificate.not_after = Time.now + 3600
    factory = OpenSSL::X509::ExtensionFactory.new(certificate, certificate)
    certificate.add_extension(factory.create_extension("subjectAltName", "IP:127.0.0.1", false))
    certificate.sign(key, OpenSSL::Digest.new("SHA256"))
    File.write(File.join(directory, "key.pem"), key.to_pem)
    File.write(File.join(directory, "cert.pem"), certificate.to_pem)
    server = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation" }, "-b", "ssl://127.0.0.1:0?key=#{directory}/key.pem&cert=#{directory}/cert.pem&verify_mode=none")
    port = Integer(server.wait_for_output(/Listening on ssl:\/\/127\.0\.0\.1:(\d+)/)[1], 10)
    https = Net::HTTP.new("127.0.0.1", port)
    https.use_ssl = true
    https.ca_file = File.join(directory, "cert.pem")
    json = { "Content-Type" => "application/json" }
    download = https.start do |http|
      part = JSON.parse(http.post("/api/rest/v1/file_actions/begin_upload/t.bin", "{}", json).body).first
      assert_equal "https://127.0.0.1:#{port}", part["upload_uri"][/\Ahttps:\/\/[^\/]+/]
      assert_equal "200", http.send_request("PUT", URI(part["upload_uri"]).request_uri, "tls").code
      finalize = { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => Digest::SHA256.hexdigest("tls"), "part" => 1 } ] }
      assert_equal "201", http.post("/api/rest/v1/files/t.bin", JSON.generate(finalize), json).code
      assert_equal "201", http.post("/__files_mock/v1/faults", JSON.generate("operation" => "transfers.download", "kind" => "truncate", "bytes" => 2), json).code
      JSON.parse(http.get("/api/rest/v1/files/t.bin").body)["download_uri"]
    end
    # A fault that writes to the connection itself works over TLS too.
    received = +""
    begin
      https.start { |http| http.get(URI(download).request_uri) { |chunk| received << chunk } }
    rescue EOFError, OpenSSL::SSL::SSLError
      nil
    end
    assert_equal "tl", received
  ensure
    server&.stop
    FileUtils.remove_entry(directory) if directory
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
    assert_equal [ "tcp://127.0.0.1:4041" ], configured(:binds, "simulation")
    assert_equal [ "tcp://0.0.0.0:4041" ], configured(:binds, nil)
  end

  # Request threads, not a buffer for every waiting connection, read request bodies, so the bodies
  # Puma holds before the simulator counts them are bounded by its thread count.
  def test_simulation_reads_each_request_body_on_its_request_thread
    assert_equal [ false, true ], [ configured(:queue_requests, "simulation"), configured(:queue_requests, nil) ]
  end

  private

  def request_head(framing)
    "POST /api/rest/v1/users HTTP/1.1\r\nHost: 127.0.0.1\r\nContent-Type: application/json\r\nConnection: close\r\n#{framing}\r\n\r\n"
  end

  def chunk(data)
    "#{data.bytesize.to_s(16)}\r\n#{data}\r\n"
  end

  # An upload part request without a content type, as the SDKs send it.
  def put_head(upload_uri, framing)
    "PUT #{URI(upload_uri).request_uri} HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n#{framing}\r\n\r\n"
  end

  def transfer_state(server)
    server.json("GET", "/__files_mock/v1/ready").last["transfers"]["state"]
  end

  # A setting Puma would use from config/puma.rb when no command-line options are given.
  def configured(setting, mode)
    script = "require 'json'; require 'puma'; require 'puma/configuration'; print JSON.generate(Puma::Configuration.new.clamp[#{setting.inspect}])"
    output = IO.popen(ServerProcess::CLEAN_ENV.merge("FILES_MOCK_MODE" => mode), [ "bundle", "exec", "ruby", "-e", script ], chdir: APP_ROOT, &:read)
    assert Process.last_status.success?, "loading config/puma.rb failed"
    JSON.parse(output)
  end
end
