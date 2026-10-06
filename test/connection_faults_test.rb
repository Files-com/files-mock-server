require_relative "test_helper"

# Faults that close or cut the connection, over a real `bundle exec puma`, observed as raw bytes.
class ConnectionFaultsTest < Minitest::Test
  def setup
    @server = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation" })
  end

  def teardown
    @server&.stop
  end

  # A request dropped before it is applied changes nothing; one dropped after it is applied has
  # changed the state although no response arrives, so a client cannot tell the two apart.
  def test_a_dropped_connection_before_or_after_the_request_is_applied
    add_fault({ "operation" => "groups.create", "kind" => "drop_before", "match" => {} })
    assert_equal "", exchange(post("/api/rest/v1/groups", { "name" => "before" }))
    assert_equal [ 200, [] ], @server.json("GET", "/api/rest/v1/groups")

    add_fault({ "operation" => "groups.create", "kind" => "drop_after" })
    assert_equal "", exchange(post("/api/rest/v1/groups", { "name" => "after" }))
    assert_equal [ 200, [ { "id" => 1, "name" => "after" } ] ], @server.json("GET", "/api/rest/v1/groups")
    entries = @server.json("GET", "/__files_mock/v1/journal").last["entries"].select { |entry| entry["operation"] == "groups.create" }
    assert_equal([ [ nil, "drop_before", nil ], [ 201, "drop_after", 0 ] ], entries.map { |entry| entry.values_at("status", "fault_kind", "sent_bytes") })
  end

  def test_download_bodies_can_be_truncated_shortened_padded_or_paused
    @server.request("POST", "/__files_mock/v1/reset", { "fixtures" => { "files" => [ { "path" => "f.bin", "text" => "0123456789" } ] } })
    {
      { "kind" => "truncate", "bytes" => 3 } => [ "10", "012" ],
      { "kind" => "short_body", "bytes" => 4 } => [ nil, "012345" ],
      { "kind" => "excess_body", "bytes" => 5 } => [ nil, "0123456789XXXXX" ],
    }.each do |rule, (length, body)|
      add_fault({ "operation" => "transfers.download" }.merge(rule))
      head, received = exchange(get(download_path("f.bin"))).split("\r\n\r\n", 2)
      assert_match(/\AHTTP\/1.1 200 OK\r\n/, head, rule["kind"])
      assert_equal [ length, "close", body ], [ head[/^content-length: (\d+)/i, 1], head[/^connection: (\S+)/i, 1], received ], rule["kind"]
    end
    # Net::HTTP ignores the early end by default and returns the short body, so the client must
    # compare it with the declared length; told not to ignore it, it raises. Retries are off because
    # Net::HTTP before 0.6 (Ruby 3.3) answers that error by sending the GET again, and the retry
    # gets the whole body: the fault applies to one request.
    add_fault({ "operation" => "transfers.download", "kind" => "truncate", "bytes" => 3 })
    Net::HTTP.start("127.0.0.1", @server.port) do |http|
      response = http.get(download_path("f.bin"))
      assert_equal [ "10", "012" ], [ response["content-length"], response.body ]
    end
    add_fault({ "operation" => "transfers.download", "kind" => "truncate", "bytes" => 3 })
    Net::HTTP.start("127.0.0.1", @server.port) do |http|
      http.ignore_eof = false
      http.max_retries = 0
      assert_raises(EOFError) { http.get(download_path("f.bin")) }
    end

    add_fault({ "operation" => "transfers.download", "kind" => "stall", "bytes" => 4, "delay_ms" => 600 })
    socket = TCPSocket.new("127.0.0.1", @server.port)
    socket.write(get(download_path("f.bin")))
    received = +""
    received << socket.readpartial(4096) until received.end_with?("\r\n\r\n0123")
    paused = now
    rest = socket.read
    assert_equal [ "456789", true ], [ rest, now - paused >= 0.5 ]
    entries = @server.json("GET", "/__files_mock/v1/journal").last["entries"].select { |entry| entry["operation"] == "transfers.download" }
    assert_equal([ [ "truncate", 10, 3 ], [ "short_body", 10, 6 ], [ "excess_body", 10, 15 ], [ "truncate", 10, 3 ], [ "truncate", 10, 3 ], [ "stall", 10, 10 ] ],
                 entries.map { |entry| entry.values_at("fault_kind", "body_bytes", "sent_bytes") }
                )
  ensure
    socket&.close
  end

  # A request's bytes_transferred counts the stored bytes its storage response was made from, as the
  # historical producer counted the bytes it read from the remote, not what reached the client: a
  # truncated body delivers fewer (the journal's sent_bytes). A withheld size sends the same bytes
  # without Content-Length (Puma sends them chunked to an HTTP/1.1 client), and a truncated one then
  # ends at the connection's close, with nothing that tells the client it was cut.
  def test_a_download_request_counts_the_bytes_its_response_was_made_from
    files = [ { "path" => "f.bin", "text" => "0123456789" } ]
    [ "sent", "withheld" ].each do |size|
      @server.request("POST", "/__files_mock/v1/reset", { "profile" => { "download" => { "request_status" => {}, "size" => size } }, "fixtures" => { "files" => files } })
      path = download_path("f.bin")
      add_fault({ "operation" => "transfers.download", "kind" => "truncate", "bytes" => 3 })
      head, received = exchange(get(path)).split("\r\n\r\n", 2)
      assert_equal [ "012", (size == "sent" ? "10" : nil) ], [ received, head[/^content-length: (\d+)/i, 1] ], size
      status, body = @server.json("GET", "#{path}/#{head[/^x-files-download-request-id: (\h+)/i, 1]}")
      assert_equal [ 200, "completed", 10 ], [ status, *body["data"].values_at("status", "bytes_transferred") ], size
      entry = @server.json("GET", "/__files_mock/v1/journal").last["entries"].find { |candidate| candidate["operation"] == "transfers.download" }
      assert_equal [ 1, 10, 10, 3 ], entry.values_at("download_request", "bytes", "body_bytes", "sent_bytes"), size
    end

    path = download_path("f.bin")
    response = Net::HTTP.start("127.0.0.1", @server.port) { |http| http.get(path) }
    assert_equal [ nil, "chunked", "0123456789" ], [ response["content-length"], response["transfer-encoding"], response.body ]
    status, body = @server.json("GET", "#{path}/#{response["x-files-download-request-id"]}")
    assert_equal [ 200, 10 ], [ status, body.dig("data", "bytes_transferred") ]
  end

  # A client that stops waiting ends the hold: the request is then applied at once, and the journal
  # says how long it was held and that its client closed the connection.
  def test_a_hold_ends_when_the_client_closes_its_connection
    add_fault({ "operation" => "groups.create", "kind" => "hold", "delay_ms" => 60_000 })
    started = now
    assert_raises(Net::ReadTimeout) do
      Net::HTTP.start("127.0.0.1", @server.port, read_timeout: 1) { |http| http.post("/api/rest/v1/groups", JSON.generate({ "name" => "held" }), "Content-Type" => "application/json") }
    end
    until (entry = @server.json("GET", "/__files_mock/v1/journal").last["entries"].find { |candidate| candidate["operation"] == "groups.create" })
      raise "the held request was not journaled within 10 seconds" if now - started > 10

      sleep 0.1
    end
    assert_equal [ 201, "hold", "client-closed" ], entry.values_at("status", "fault_kind", "hold_ended")
    assert_operator entry["held_ms"], :<, 5_000
    assert_equal [ 200, [ { "id" => 1, "name" => "held" } ] ], @server.json("GET", "/api/rest/v1/groups")
    assert_equal 0, @server.json("GET", "/__files_mock/v1/faults").last["holding"], "the ended hold gave its place back"
  end

  # Two requests being held keep their rules' places: with three Puma threads, a third hold rule is
  # refused, so a thread stays free and the control API answers while both are held. A reset ends
  # them, and once they have been answered their places can be taken again.
  def test_requests_being_held_keep_their_places_and_the_control_api_stays_available
    @server.stop
    @server = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation" }, "-t", "0:3")
    2.times { |index| add_fault({ "operation" => "groups.find", "match" => { "id" => index + 1 }, "kind" => "hold", "delay_ms" => 60_000 }) }
    held = [ 1, 2 ].map do |id|
      socket = TCPSocket.new("127.0.0.1", @server.port)
      socket.write("GET /api/rest/v1/groups/#{id} HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n")
      socket
    end
    started = now
    until (faults = @server.json("GET", "/__files_mock/v1/faults").last)["holding"] == 2
      raise "the two requests were not held within 10 seconds: #{faults.inspect}" if now - started > 10

      sleep 0.05
    end
    assert_equal 0, faults["pending"]
    third = @server.json("POST", "/__files_mock/v1/faults", { "operation" => "groups.list", "kind" => "hold", "delay_ms" => 1 })
    assert_equal [ 409, "At most 2 hold rules can be pending or holding a request at once" ], [ third.first, third.last["error"] ]
    assert_equal 200, @server.json("GET", "/__files_mock/v1/ready").first
    assert_equal [ 200, [] ], @server.json("GET", "/api/rest/v1/groups")
    assert_equal 200, @server.json("POST", "/__files_mock/v1/reset", {}).first

    held.each do |socket|
      assert socket.wait_readable(10), "a held request was not answered after the reset"
      assert_match(/\AHTTP\/1.1 409 /, socket.readpartial(4096))
    end
    assert_equal 0, @server.json("GET", "/__files_mock/v1/faults").last["holding"]
    add_fault({ "operation" => "groups.create", "kind" => "hold", "delay_ms" => 200 })
    assert_equal 201, @server.json("POST", "/api/rest/v1/groups", { "name" => "again" }).first
    2.times { |index| add_fault({ "operation" => "groups.find", "match" => { "id" => index + 1 }, "kind" => "hold", "delay_ms" => 1 }) }
    stale = @server.json("GET", "/__files_mock/v1/journal").last["entries"].select { |entry| entry["operation"] == "groups.find" }
    assert_equal([ [ 409, "reset" ] ] * 2, stale.map { |entry| entry.values_at("status", "hold_ended") })
  ensure
    held&.each(&:close)
  end

  private

  def add_fault(rule)
    status, body = @server.json("POST", "/__files_mock/v1/faults", rule)
    assert_equal 201, status, body.inspect
  end

  def download_path(path)
    URI(@server.json("GET", "/api/rest/v1/files/#{path}").last.fetch("download_uri")).request_uri
  end

  def post(path, body)
    json = JSON.generate(body)
    "POST #{path} HTTP/1.1\r\nHost: 127.0.0.1\r\nContent-Type: application/json\r\nContent-Length: #{json.bytesize}\r\n\r\n#{json}"
  end

  def get(path)
    "GET #{path} HTTP/1.1\r\nHost: 127.0.0.1\r\n\r\n"
  end

  # Everything the server sends before it closes the connection.
  def exchange(request)
    socket = TCPSocket.new("127.0.0.1", @server.port)
    socket.write(request)
    raise "the server did not close the connection within 10 seconds" unless socket.wait_readable(10)

    socket.read.to_s.b
  ensure
    socket&.close
  end

  def now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end
