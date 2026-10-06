require_relative "test_helper"

class TransfersTest < Minitest::Test
  include SimulationRequests
  include FileRequests

  # Every byte value, in an order that is not text, so a transfer that alters or reorders bytes shows.
  SOURCE = (0...300).map { |index| ((index * 37) + 11) % 256 }.pack("C*").freeze
  # A slash, a space, Unicode and a literal percent sequence that decoding twice would turn into a slash.
  PATH = "folder/sp ace-%2F-雪.bin".freeze

  def setup
    @app = new_app
  end

  def test_bytes_round_trip_at_a_path_encoded_the_way_each_sdk_encodes_it
    # Go keeps the path's slashes; Python encodes them too. Either way the path is decoded exactly once.
    python_route = ERB::Util.url_encode(PATH)
    created = upload(PATH, [ SOURCE ], finalize: { "size" => 300, "mkdir_parents" => true })
    assert_equal 201, created.status
    assert_equal [ PATH, "sp ace-%2F-雪.bin", "file", 300 ], created.json.values_at("path", "display_name", "type", "size")
    assert_match(/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, created.json["mtime"])

    assert_equal created.json, api("GET", "/file_actions/metadata/#{python_route}").json
    negotiated = api("GET", "/files/#{python_route}", { "path" => PATH })
    assert_equal created.json, negotiated.json.except("download_uri")
    assert negotiated.json["download_uri"].start_with?("#{ORIGIN}/__files_mock/transfer/download/")
    downloaded = transfer("GET", negotiated.json["download_uri"])
    assert_equal [ 200, SOURCE ], [ downloaded.status, downloaded.body ]
    assert_equal({ "content-type" => "application/octet-stream", "content-length" => "300", "accept-ranges" => "bytes", "etag" => %("#{Digest::SHA256.hexdigest(SOURCE)}") }, downloaded.headers.slice("content-type", "content-length", "accept-ranges", "etag"))
  end

  def test_parts_are_joined_in_part_number_order_and_committed_once
    first = begin_upload("a.bin")
    profile = { "part_number" => 1, "partsize" => 1_048_576, "next_partsize" => 1_048_576, "parallel_parts" => false, "retry_parts" => true, "http_method" => "PUT", "path" => "a.bin" }
    assert_equal profile, first.slice(*profile.keys)
    assert_operator Time.iso8601(first["expires"]), :>, Time.now
    second = begin_upload("a.bin", { "ref" => first["ref"], "part" => 2 })
    assert_equal [ first["ref"], 2 ], second.values_at("ref", "part_number")
    refute_equal first["upload_uri"], second["upload_uri"]

    # Part 2 arrives and is listed first, and the Go SDK sends part numbers as strings; part 1 still comes first.
    etag2 = put_part(second, "world")
    etag1 = put_part(first, "hello ")
    created = api("POST", "/files/a.bin", { "action" => "end", "ref" => first["ref"], "etags" => [ { "etag" => etag2, "part" => "2" }, { "etag" => %("#{etag1}"), "part" => 1 } ] })
    assert_equal [ 201, 11 ], [ created.status, created.json["size"] ]
    assert_equal "hello world", download("a.bin").body

    replaced = upload("a.bin", [ "replaced" ])
    assert_equal [ 200, "replaced" ], [ replaced.status, download("a.bin").body ]
    finalized = journaled("files.finalize_upload", %w[upload version bytes sha256 status])
    assert_equal [ [ 1, 1, 11, Digest::SHA256.hexdigest("hello world"), 201 ], [ 2, 2, 8, Digest::SHA256.hexdigest("replaced"), 200 ] ], finalized
    assert_equal [ [ 1, 2, 5, etag2 ], [ 1, 1, 6, etag1 ] ], journaled("transfers.upload_part", %w[upload part bytes sha256]).first(2)
  end

  def test_empty_files_and_zero_length_terminal_parts_are_valid
    # The Go SDK sends one empty part, no size, and its part number as a string.
    part = begin_upload("go-empty.bin", { "mkdir_parents" => true, "with_direct_connection_info" => true })
    created = api("POST", "/files/go-empty.bin", { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => put_part(part, ""), "part" => "1" } ], "mkdir_parents" => true })
    assert_equal [ 201, 0 ], [ created.status, created.json["size"] ]
    downloaded = download("go-empty.bin")
    assert_equal [ 200, "", "0" ], [ downloaded.status, downloaded.body, downloaded.headers["content-length"] ]

    # The Python SDK ends a file that fills its last part exactly with an extra empty part, and sends the size.
    assert_equal 201, upload("python-exact.bin", [ "abcd", "efgh", "" ], finalize: { "size" => 8 }).status
    assert_equal "abcdefgh", download("python-exact.bin").body
  end

  def test_invalid_finalize_is_refused_before_anything_is_published
    assert_equal 201, upload("kept.bin", [ "original" ]).status
    first = begin_upload("kept.bin")
    second = begin_upload("kept.bin", { "ref" => first["ref"], "part" => 2 })
    listed = [ { "etag" => put_part(first, "new "), "part" => 1 }, { "etag" => put_part(second, "bytes"), "part" => 2 } ]
    finalize = ->(params) { api("POST", "/files/kept.bin", { "action" => "end", "ref" => first["ref"], "etags" => listed }.merge(params)) }
    {
      "a listed part never uploaded" => [ finalize.call({ "etags" => listed + [ { "etag" => listed[1]["etag"], "part" => 3 } ] }), 422, "processing-failure/file-not-uploaded" ],
      "a wrong ETag" => [ finalize.call({ "etags" => [ listed[0], listed[1].merge("etag" => listed[0]["etag"]) ] }), 422, "processing-failure/file-not-uploaded" ],
      "a part listed twice" => [ finalize.call({ "etags" => [ listed[0], listed[0], listed[1] ] }), 422, "bad-request/invalid-etags" ],
      "a gap before the listed parts" => [ finalize.call({ "etags" => [ listed[1] ] }), 422, "bad-request/invalid-etags" ],
      "an uploaded part left out" => [ finalize.call({ "etags" => [ listed[0] ] }), 422, "bad-request/invalid-etags" ],
      "no parts" => [ finalize.call({ "etags" => [] }), 422, "processing-failure/file-not-uploaded" ],
      "a part number that is not a whole number" => [ finalize.call({ "etags" => [ listed[0].merge("part" => "1x"), listed[1] ] }), 422, "bad-request" ],
      "a size the parts do not add up to" => [ finalize.call({ "size" => 10 }), 422, "bad-request/request-params-invalid" ],
      "no ref" => [ finalize.call({ "ref" => nil }), 422, "bad-request/request-params-required" ],
      "an unknown ref" => [ finalize.call({ "ref" => "00" }), 404, "not-found/file-upload-not-found" ],
      "another file's ref" => [ finalize.call({ "ref" => begin_upload("other.bin")["ref"] }), 404, "not-found/file-upload-not-found" ],
    }.each do |name, (response, status, type)|
      assert_equal [ status, type ], [ response.status, response.json["type"] ], name
      assert_equal "original", download("kept.bin").body, name
    end

    # Every refusal left the upload open. Once it is finalized, its ref cannot publish again.
    assert_equal 200, finalize.call({}).status
    again = finalize.call({})
    assert_equal [ 404, "not-found/file-upload-not-found" ], [ again.status, again.json["type"] ]
    published = journaled("files.finalize_upload", %w[status]).flatten.select { |status| status < 300 }
    assert_equal [ "new bytes", [ 201, 200 ] ], [ download("kept.bin").body, published ]
  end

  # The .NET SDK finalizes a sequential upload with ref, size and provided_mtime, and no etags, as
  # Files.com native storage allows: the upload's received parts become the file.
  def test_a_sequential_upload_of_known_size_is_finalized_from_its_received_parts_without_etags
    dotnet = ->(path, parts, size) { finalize_received(path, parts, { "size" => size, "provided_mtime" => "2026-09-24 00:00:00Z" }) }
    created = dotnet.call("dotnet.bin", [ SOURCE[0, 120], SOURCE[120..] ], 300)
    assert_equal [ 201, 300, "2026-09-24T00:00:00Z" ], [ created.status, created.json["size"], created.json["provided_mtime"] ]
    assert_equal SOURCE, download("dotnet.bin").body
    # An empty file is one empty part, never no parts.
    assert_equal([ 201, 0 ], dotnet.call("empty.bin", [ "" ], 0).then { |response| [ response.status, response.json["size"] ] })
    assert_equal "", download("empty.bin").body
    assert_equal [ [ 300, Digest::SHA256.hexdigest(SOURCE), 201 ], [ 0, Digest::SHA256.hexdigest(""), 201 ] ], journaled("files.finalize_upload", %w[bytes sha256 status])
  end

  def test_finalizing_without_etags_refuses_what_the_received_parts_cannot_establish
    assert_equal 201, upload("kept.bin", [ "original" ]).status
    unsent = begin_upload("kept.bin")
    first = begin_upload("kept.bin")
    third = begin_upload("kept.bin", { "ref" => first["ref"], "part" => 3 })
    put_part(first, "one ")
    put_part(third, "three")
    whole = begin_upload("kept.bin")
    put_part(whole, "new bytes")
    finalize = ->(part, params) { api("POST", "/files/kept.bin", { "action" => "end", "ref" => part["ref"] }.merge(params)) }
    {
      "no part received" => [ finalize.call(unsent, { "size" => 0 }), 422, "processing-failure/file-not-uploaded" ],
      "a gap in the received parts" => [ finalize.call(first, { "size" => 9 }), 501, "simulation/not-supported" ],
      "a size the parts do not add up to" => [ finalize.call(whole, { "size" => 8 }), 422, "bad-request/request-params-invalid" ],
      "no size" => [ finalize.call(whole, {}), 501, "simulation/not-supported" ],
      # Supplied etags are checked as always, and never replaced by the received parts.
      "etags null" => [ finalize.call(whole, { "size" => 9, "etags" => nil }), 501, "simulation/not-supported" ],
      "etags empty" => [ finalize.call(whole, { "size" => 9, "etags" => [] }), 422, "processing-failure/file-not-uploaded" ],
      "a wrong etag" => [ finalize.call(whole, { "size" => 9, "etags" => [ { "etag" => "0" * 64, "part" => 1 } ] }), 422, "processing-failure/file-not-uploaded" ],
    }.each do |name, (response, status, type)|
      assert_equal [ status, type ], [ response.status, response.json["type"] ], name
      assert_equal "original", download("kept.bin").body, name
    end
    assert_equal 200, finalize.call(whole, { "size" => 9 }).status
    assert_equal "new bytes", download("kept.bin").body
  end

  def test_sending_a_stored_part_again_needs_the_same_bytes
    part = begin_upload("retried.bin")
    first = transfer("PUT", part["upload_uri"], "same bytes")
    held = bytes_in_use
    again = transfer("PUT", part["upload_uri"], "same bytes")
    assert_equal [ 200, first.headers["etag"], held ], [ again.status, again.headers["etag"], bytes_in_use ]

    changed = transfer("PUT", part["upload_uri"], "other bytes")
    assert_equal [ 501, "simulation/not-supported", held ], [ changed.status, changed.json["type"], bytes_in_use ]
    assert_equal "same bytes", finalize_and_download("retried.bin", part, [ first.headers["etag"] ])
  end

  def test_one_byte_range_is_sent_exactly_and_other_ranges_get_the_whole_file
    upload("ranged.bin", [ SOURCE[0, 100], SOURCE[100..] ])
    url = download_url("ranged.bin")
    { "bytes=7-299" => 7..299, "bytes=90-110" => 90..110, "bytes=250-" => 250..299, "bytes=-5" => 295..299, "bytes=290-5000" => 290..299, "bytes=0-0" => 0..0 }.each do |range, selected|
      response = transfer("GET", url, nil, { "HTTP_RANGE" => range })
      assert_equal [ 206, SOURCE[selected], "bytes #{selected.begin}-#{selected.end}/300", selected.count.to_s ],
                   [ response.status, response.body, response.headers["content-range"], response.headers["content-length"] ], range
    end
    [ "bytes=300-", "bytes=1000-2000", "bytes=-0" ].each do |range|
      response = transfer("GET", url, nil, { "HTTP_RANGE" => range })
      assert_equal [ 416, "bytes */300" ], [ response.status, response.headers["content-range"] ], range
    end
    [ "bytes=0-1,5-6", "bytes=9-2", "items=0-1", "bytes=one-two" ].each do |range|
      response = transfer("GET", url, nil, { "HTTP_RANGE" => range })
      assert_equal [ 200, SOURCE, nil ], [ response.status, response.body, response.headers["content-range"] ], range
    end

    upload("empty.bin", [ "" ])
    empty = transfer("GET", download_url("empty.bin"), nil, { "HTTP_RANGE" => "bytes=0-" })
    assert_equal [ 200, "" ], [ empty.status, empty.body ]
  end

  def test_a_download_url_names_one_version_and_a_download_in_progress_finishes_from_it
    upload("versioned.bin", [ "first version" ])
    old_url = download_url("versioned.bin")
    status, _headers, body = app.call(Rack::MockRequest.env_for(URI(old_url).request_uri, "HTTP_RANGE" => "bytes=6-"))
    assert_equal 206, status

    assert_equal 200, upload("versioned.bin", [ "second" ]).status
    assert_equal 19, bytes_in_use, "the version still being sent stays counted"
    assert_equal "version", read_and_close(body)
    assert_equal 6, bytes_in_use

    refused = transfer("GET", old_url)
    assert_equal [ 409, "download_source_changed" ], [ refused.status, refused.json["type"] ]
    assert_equal "second", download("versioned.bin").body
  end

  def test_reset_invalidates_refs_and_urls_but_lets_a_download_in_progress_finish
    upload("kept.bin", [ SOURCE ])
    url = download_url("kept.bin")
    part = begin_upload("open.bin")
    put_part(part, "part one")
    _status, _headers, body = app.call(Rack::MockRequest.env_for(URI(url).request_uri))
    reset
    assert_equal SOURCE.bytesize, bytes_in_use, "the download started before the reset still holds its version"
    assert_equal SOURCE, read_and_close(body)
    assert_equal 0, bytes_in_use

    # Numbers restart at every reset: upload 2 is open for open.bin and version 1 is kept.bin again, as
    # before the reset. The old handles still name nothing.
    assert_equal 201, upload("kept.bin", [ "new bytes" ]).status
    assert_equal part["path"], begin_upload("open.bin")["path"]
    {
      "next part" => api("POST", "/file_actions/begin_upload/open.bin", { "ref" => part["ref"], "part" => 2 }),
      "part bytes" => transfer("PUT", part["upload_uri"], "part two"),
      "finalize" => api("POST", "/files/open.bin", { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => "x", "part" => 1 } ] }),
    }.each { |name, response| assert_equal [ 404, "not-found/file-upload-not-found" ], [ response.status, response.json["type"] ], name }
    stale_download = transfer("GET", url)
    assert_equal [ 404, "not-found" ], [ stale_download.status, stale_download.json["type"] ]
    assert_equal "new bytes".bytesize, bytes_in_use

    # A part body still arriving when the simulator is reset is refused, not stored in the new state.
    fresh = begin_upload("late.bin")
    input = InterruptedBody.new("late bytes", -> { reset })
    late = app.call(Rack::MockRequest.env_for(URI(fresh["upload_uri"]).request_uri, method: "PUT", input:))
    assert_equal [ 409, "simulation/stale-request" ], [ late[0], JSON.parse(read_and_close(late[2]))["type"] ]
    assert_equal({ "uploads" => 0, "files" => 0, "bytes_in_use" => 0 }, control("GET", "ready").json["transfers"]["state"])
  end

  def test_a_part_fault_fails_one_path_and_part_before_anything_is_stored
    a1 = begin_upload("a.bin")
    a2 = begin_upload("a.bin", { "ref" => a1["ref"], "part" => 2 })
    b1 = begin_upload("b.bin")
    b2 = begin_upload("b.bin", { "ref" => b1["ref"], "part" => 2 })
    rule = add_fault({ "operation" => "transfers.upload_part", "match" => { "path" => "a.bin", "part" => 2 }, "status" => 503, "retry_after" => 0 })
    etags = { a1 => put_part(a1, "a-one "), b2 => put_part(b2, "b-two") }
    held = bytes_in_use

    faulted = transfer("PUT", a2["upload_uri"], "a-two")
    assert_equal [ 503, "0", "simulation/injected-fault", held ], [ faulted.status, faulted.headers["retry-after"], faulted.json["type"], bytes_in_use ]
    etags[a2] = put_part(a2, "a-two")
    etags[b1] = put_part(b1, "b-one ")
    assert_equal "a-one a-two", finalize_and_download("a.bin", a1, etags.values_at(a1, a2))
    assert_equal "b-one b-two", finalize_and_download("b.bin", b1, etags.values_at(b1, b2))

    fault = control("GET", "faults").json["faults"].first
    assert_equal [ "consumed", 1 ], fault.values_at("state", "matched_requests")
    entry = journal.detect { |candidate| candidate["seq"] == fault["consumed_by_request"] }
    assert_equal [ "transfers.upload_part", 1, 2, 503, rule["id"] ], entry.values_at("operation", "upload", "part", "status", "fault_id")
  end

  def test_a_finalize_or_download_fault_fails_once_before_publishing_or_sending
    upload("kept.bin", [ "original" ])
    part = begin_upload("kept.bin")
    etag = put_part(part, "replacement")
    add_fault({ "operation" => "files.finalize_upload", "match" => { "path" => "kept.bin" }, "status" => 500 })
    add_fault({ "operation" => "transfers.download", "match" => { "path" => "kept.bin" }, "status" => 502 })
    finalize = -> { api("POST", "/files/kept.bin", { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => etag, "part" => 1 } ] }) }

    assert_equal 500, finalize.call.status
    assert_equal 502, download("kept.bin").status
    assert_equal "original", download("kept.bin").body
    assert_equal 200, finalize.call.status
    assert_equal "replacement", download("kept.bin").body
    assert_equal [ 0, 2 ], control("GET", "faults").json.values_at("pending", "consumed")
  end

  def test_limits_refuse_transfers_before_the_bytes_are_held
    simulator = new_app(max_transfer_bytes: 10, max_records: 1)
    part = begin_upload("a.bin", to: simulator)
    unread = InterruptedBody.new("eleven byte", -> { flunk "a body over the transfer limit was read" })
    over = transfer("PUT", part["upload_uri"], unread, to: simulator)
    assert_equal [ 409, "simulation/limit-exceeded", 0 ], [ over.status, over.json["type"], bytes_in_use(to: simulator) ]

    etag = transfer("PUT", part["upload_uri"], "ten bytes!", to: simulator).headers["etag"].delete('"')
    other = begin_upload("b.bin", to: simulator)
    assert_equal 409, transfer("PUT", other["upload_uri"], "x", to: simulator).status
    assert_equal 201, api("POST", "/files/a.bin", { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => etag, "part" => 1 } ] }, to: simulator).status
    assert_equal 10, bytes_in_use(to: simulator)

    empty = begin_upload("c.bin", to: simulator)
    empty_etag = transfer("PUT", empty["upload_uri"], "", to: simulator).headers["etag"].delete('"')
    too_many_files = api("POST", "/files/c.bin", { "action" => "end", "ref" => empty["ref"], "etags" => [ { "etag" => empty_etag, "part" => 1 } ] }, to: simulator)
    assert_equal [ 409, "simulation/limit-exceeded" ], [ too_many_files.status, too_many_files.json["type"] ]
    reset({}, to: simulator)
    assert_equal 0, bytes_in_use(to: simulator)
  end

  def test_uploads_and_their_parts_are_limited_in_number
    uploads = Array.new(FilesMockServer::Simulation::Files::MAX_UPLOADS) { |number| begin_upload("file#{number}.bin") }
    refused = api("POST", "/file_actions/begin_upload/one-more.bin", {})
    assert_equal [ 409, "simulation/limit-exceeded" ], [ refused.status, refused.json["type"] ]

    ref = uploads.first["ref"]
    { FilesMockServer::Simulation::Files::MAX_PARTS + 1 => [ 409, "simulation/limit-exceeded" ], 0 => [ 422, "bad-request/part-number-too-large" ] }.each do |part, expected|
      response = api("POST", "/file_actions/begin_upload/file0.bin", { "ref" => ref, "part" => part })
      assert_equal expected, [ response.status, response.json["type"] ], part
    end
  end

  # parts asks begin_upload for consecutive parts of one upload in one response: from part 1 for a
  # new upload, whatever part it sends, and from part for a renewal, which may repeat parts.
  def test_begin_upload_issues_consecutive_parts_in_one_response
    assert_equal 1, begin_upload("one.bin", { "parts" => 1 })["part_number"]
    batch = begin_batch("batch.bin", { "parts" => 3, "part" => 7 })
    assert_equal [ [ 1, 2, 3 ], 1 ], [ batch.map { |part| part["part_number"] }, batch.map { |part| part["ref"] }.uniq.size ]
    renewed = begin_batch("batch.bin", { "ref" => batch.first["ref"], "part" => 2, "parts" => "3" })
    assert_equal [ [ 2, 3, 4 ], [ batch.first["ref"] ] ], [ renewed.map { |part| part["part_number"] }, renewed.map { |part| part["ref"] }.uniq ]
    etags = ([ batch.first ] + renewed).zip(%w[a b c d]).map { |part, bytes| { "etag" => put_part(part, bytes), "part" => part["part_number"] } }
    assert_equal 201, api("POST", "/files/batch.bin", { "action" => "end", "ref" => batch.first["ref"], "etags" => etags }).status
    assert_equal "abcd", download("batch.bin").body

    last = FilesMockServer::Simulation::Files::MAX_PARTS
    edge = begin_upload("edge.bin")
    assert_equal(((last - 4)..last).to_a, begin_batch("edge.bin", { "ref" => edge["ref"], "part" => last - 4, "parts" => 5 }).map { |part| part["part_number"] })
    assert_equal((1..last).to_a, begin_batch("whole.bin", { "parts" => last }).map { |part| part["part_number"] })
  end

  # A count that is not a whole number from 1, or a range that ends past the part limit, is refused
  # before any folder, upload number, byte or part is held.
  def test_an_invalid_batch_is_refused_before_anything_changes
    last = FilesMockServer::Simulation::Files::MAX_PARTS
    held = begin_upload("held.bin")
    put_part(held, "abc")
    before = transfer_state
    {
      { "parts" => 0 } => [ 422, "bad-request" ],
      { "parts" => -1 } => [ 422, "bad-request" ],
      { "parts" => 1.5 } => [ 422, "bad-request" ],
      { "parts" => "2x" } => [ 422, "bad-request" ],
      { "parts" => last + 1 } => [ 409, "simulation/limit-exceeded" ],
    }.each do |params, expected|
      response = api("POST", "/file_actions/begin_upload/new/dir/f.bin", params.merge("mkdir_parents" => true))
      assert_equal expected, [ response.status, response.json["type"] ], params
    end
    [ [ last - 4, 6, 409 ], [ last + 1, 1, 409 ], [ 2, 0, 422 ] ].each do |part, parts, status|
      response = api("POST", "/file_actions/begin_upload/held.bin", { "ref" => held["ref"], "part" => part, "parts" => parts })
      assert_equal status, response.status, [ part, parts ]
    end
    assert_equal before, transfer_state
    assert_equal 404, api("GET", "/file_actions/metadata/new").status
    begin_upload("after.bin")
    assert_equal [ 1, 2 ], journaled("files.begin_upload", %w[status upload]).select { |status, _| status == 200 }.map(&:last)
    etag = put_part(begin_upload("held.bin", { "ref" => held["ref"], "part" => 2 }), "de")
    etags = [ { "etag" => Digest::SHA256.hexdigest("abc"), "part" => 1 }, { "etag" => etag, "part" => 2 } ]
    assert_equal "abcde", finalize_and_download("held.bin", held, etags.map { |entry| entry["etag"] })
  end

  # The Ruby SDK sends a form body. Rack parses it within the body limit and its own nesting and
  # parameter limits into strings, arrays and hashes that the schema then converts as it converts
  # JSON, and a body value wins over a query value of the same name.
  def test_a_form_body_is_parsed_by_rack_and_converted_like_json
    path = "sp ace/f+.bin"
    begun = form("POST", "/file_actions/begin_upload/#{route(path)}?parts=1", "parts=2&mkdir_parents=true&size=5")
    assert_equal [ 200, [ 1, 2 ] ], [ begun.status, begun.json.map { |part| part["part_number"] } ]
    etags = begun.json.zip(%w[abc de]).map { |part, bytes| "etags[][etag]=#{put_part(part, bytes)}&etags[][part]=#{part["part_number"]}" }
    body = "action=end&ref=#{begun.json.first["ref"]}&size=5&#{etags.join("&")}&provided_mtime=2023-11-14+23%3A13%3A20+%2B0100"
    created = form("POST", "/files/#{route(path)}?provided_mtime=not+a+time&size=999", body)
    assert_equal [ 201, "sp ace/f+.bin", 5, "2023-11-14T22:13:20Z" ], [ created.status, *created.json.values_at("path", "size", "provided_mtime") ]
    assert_equal "abcde", download(path).body
    assert_equal({ "action" => "string", "ref" => "string", "size" => "string", "etags" => "array", "provided_mtime" => "string" }, journal.reverse.find { |entry| entry["operation"] == "files.finalize_upload" }["wire"])

    before = transfer_state
    {
      "a percent sequence that does not decode" => "size=%zz",
      "an array and a hash under one name" => "etags[]=a&etags[x]=b",
      "names nested past Rack's depth limit" => "a#{"[b]" * 32}=1",
    }.each do |name, refused_body|
      refused = form("POST", "/file_actions/begin_upload/refused.bin", refused_body)
      assert_equal [ 422, "bad-request/invalid-body", "The request body is not valid application/x-www-form-urlencoded" ], [ refused.status, *refused.json.values_at("type", "error") ], name
    end
    query = form("POST", "/file_actions/begin_upload/refused.bin", "size=1", { "QUERY_STRING" => "size=%zz" })
    assert_equal [ 422, "bad-request", "The query string is invalid" ], [ query.status, *query.json.values_at("type", "error") ]
    assert_equal 413, form("POST", "/file_actions/begin_upload/refused.bin", "size=1&mkdir_parents=true", to: new_app(max_body_bytes: 16)).status
    assert_equal before, transfer_state
    assert_equal 404, api("GET", "/file_actions/metadata/refused.bin").status
  end

  def test_interleaved_and_concurrent_uploads_keep_their_own_bytes
    a1 = begin_upload("a.bin")
    b1 = begin_upload("b.bin")
    a2 = begin_upload("a.bin", { "ref" => a1["ref"], "part" => 2 })
    b2 = begin_upload("b.bin", { "ref" => b1["ref"], "part" => 2 })
    etags = [ a1, b1, a2, b2 ].zip(%w[A1 B1 A2 B2]).to_h { |part, bytes| [ part, put_part(part, bytes) ] }
    assert_equal "A1A2", finalize_and_download("a.bin", a1, etags.values_at(a1, a2))
    assert_equal "B1B2", finalize_and_download("b.bin", b1, etags.values_at(b1, b2))

    contents = Array.new(8) { |number| SOURCE.bytes.rotate(number * 31).pack("C*") }
    threads = contents.each_with_index.map { |content, number| Thread.new { upload("concurrent#{number}.bin", [ content[0, 150], content[150..] ]).status } }
    assert_equal [ 201 ], threads.map(&:value).uniq
    contents.each_with_index { |content, number| assert_equal content, download("concurrent#{number}.bin").body, number }
  end

  def test_provided_mtime_accepts_the_utc_times_the_python_dotnet_and_ruby_sdks_send
    {
      "2023-11-14T22:13:20" => "2023-11-14T22:13:20Z",
      "2023-11-14T22:13:20.123456" => "2023-11-14T22:13:20Z",
      "2023-11-14T23:13:20+01:00" => "2023-11-14T22:13:20Z",
      # .NET's DateTime.ToString("u").
      "2023-11-14 22:13:20Z" => "2023-11-14T22:13:20Z",
      # Ruby's Time#to_s.
      "2023-11-14 23:13:20 +0100" => "2023-11-14T22:13:20Z",
      "2023-11-14 22:13:20 UTC" => "2023-11-14T22:13:20Z",
      "2023-12-31 23:30:00 -0100" => "2024-01-01T00:30:00Z",
      "2024-02-29 12:00:00 +2359" => "2024-02-28T12:01:00Z",
    }.each_with_index do |(sent, stored), number|
      created = upload("mtime#{number}.bin", [ "x" ], finalize: { "provided_mtime" => sent })
      assert_equal [ 201, stored ], [ created.status, created.json["provided_mtime"] ], sent
    end
    [ "2023-02-30T00:00:00", "not a time", "2023-02-30 00:00:00Z", "2023-11-14 24:00:00Z", "2023-11-14 22:13:60Z", "2023-11-14 22:13:20",
      "2023-11-14 22:13:20+01:00", "2023-11-14 22:13:20.5Z", "2023-11-14 22:13:20Z ", "2023-11-14  22:13:20Z",
      "2023-02-29 00:00:00 UTC", "2023-11-14 24:00:00 +0000", "2023-11-14 22:13:60 UTC", "2023-11-14 22:13:20 +2400", "2023-11-14 22:13:20 +0160",
      "2023-11-14 22:13:20 +01:00", "2023-11-14 22:13:20 +100", "2023-11-14 22:13:20 utc", "2023-11-14 22:13:20 GMT", "2023-11-14 22:13:20  UTC",
      "2023-11-14 22:13:20 +0100 ", "2023-11-14T22:13:20 UTC", "2023-11-14 22:13:20.5 UTC" ].each do |sent|
      response = upload("rejected.bin", [ "x" ], finalize: { "provided_mtime" => sent })
      assert_equal [ 422, "provided_mtime is invalid" ], [ response.status, response.json["error"] ], sent
    end
  end

  def test_names_the_api_rejects_as_ambiguous_are_refused_before_anything_is_held
    upload("kept.bin", [ "kept" ])
    held = transfer_state
    # Compared as the API compares paths, a fullwidth dot pair is "..", a fullwidth solidus and the
    # account-of sign contain a slash, and a lone combining dot or a no-break space is empty.
    [ "folder/\uFF0E\uFF0E/escape", "parent/child\uFF0Ffile.txt", "parent/child\u2100file.txt", "parent/\u0307", "parent/\u00A0/file.txt" ].each do |path|
      begun = api("POST", "/file_actions/begin_upload/#{route(path)}", {})
      assert_equal [ 501, "simulation/not-supported" ], [ begun.status, begun.json["type"] ], path
      assert_equal 501, api("GET", "/file_actions/metadata/#{route(path)}").status, path
    end
    assert_equal held, transfer_state
  end

  # The API's path helper refuses, on every file route, a path with a folder name ending in whitespace
  # (before a name it rejects as ambiguous), then a path holding a zero-width space. A file's own name
  # may end in whitespace, and declared parameters are validated before the helper runs.
  def test_the_apis_request_path_rules_refuse_folder_names_ending_in_whitespace_and_zero_width_spaces
    upload("kept.bin", [ "kept" ])
    held = [ transfer_state, control("GET", "ready").json["namespace"]["state"] ]
    {
      "bad-request/path-cannot-have-trailing-whitespace" => [ "spaced /file.txt", "tab\t/file.txt", "zero\u200B /file.txt", "spaced /\uFF0E\uFF0E/file.txt" ],
      "bad-request/invalid-path" => [ "zero\u200Bwidth.txt", "zero\u200B/file.txt", "folder/\u200B" ],
    }.each do |type, paths|
      paths.each do |path|
        [ api("POST", "/file_actions/begin_upload/#{route(path)}", {}), api("GET", "/file_actions/metadata/#{route(path)}"), api("GET", "/files/#{route(path)}"),
          api("DELETE", "/files/#{route(path)}"), api("POST", "/file_actions/copy/#{route(path)}", { "destination" => "copy.txt" }),
          api("POST", "/file_actions/unzip", { "path" => path, "destination" => "out" }) ].each do |refused|
          assert_equal [ 422, type ], [ refused.status, refused.headers["x-files-error-class"] ], "#{path.inspect}: #{refused.body}"
          assert_equal type, refused.json["type"], path.inspect
        end
      end
    end
    mistyped = api("POST", "/file_actions/begin_upload/#{route("spaced /file.txt")}", { "mkdir_parents" => "maybe" })
    assert_equal [ 422, "bad-request", "mkdir_parents is invalid" ], mistyped.json.values_at("http-code", "type", "error")
    # A destination left out fails the parameter validation, a bare bad-request; one sent null passes
    # it, so the path rules answer.
    copy = ->(params) { api("POST", "/file_actions/copy/#{route("spaced /file.txt")}", params) }
    unzip = ->(params) { api("POST", "/file_actions/unzip", { "path" => "spaced /file.txt" }.merge(params)) }
    [ copy.call({}), unzip.call({}) ].each do |missing|
      assert_equal [ 422, "bad-request", "destination is missing", "bad-request" ], [ missing.status, missing.json["type"], missing.json["error"], missing.headers["x-files-error-class"] ]
    end
    [ copy.call({ "destination" => nil }), unzip.call({ "destination" => nil }) ].each do |sent_null|
      assert_equal [ 422, "bad-request/path-cannot-have-trailing-whitespace" ], [ sent_null.status, sent_null.headers["x-files-error-class"] ]
    end
    assert_equal held, [ transfer_state, control("GET", "ready").json["namespace"]["state"] ]

    leaf = "folder/trailing \t"
    assert_equal([ 201, leaf ], upload(leaf, [ "leaf" ]).then { |created| [ created.status, created.json["path"] ] })
    assert_equal [ 200, "leaf" ], [ api("GET", "/file_actions/metadata/#{route(leaf)}").status, download(leaf).body ]
    assert_equal 204, api("DELETE", "/files/#{route(leaf)}").status
  end

  def test_other_spellings_of_existing_files_and_folders_are_refused_in_both_directions
    upload("café.bin", [ "cafe" ])
    upload("archive/café/notes.txt", [ "notes" ])
    {
      "a file inside the file" => "cafe.bin/child",
      "the file, capitalized and without its accent" => "CAFE.bin",
      "a file where the folder is" => "archive/cafe",
    }.each do |name, path|
      begun = api("POST", "/file_actions/begin_upload/#{route(path)}", {})
      assert_equal [ 501, "simulation/not-supported" ], [ begun.status, begun.json["type"] ], name
    end
    assert_equal 501, api("GET", "/file_actions/metadata/archive/CAFE").status
    # A name that only starts the same way is a different file.
    assert_equal 200, api("POST", "/file_actions/begin_upload/#{route("café.bin.bak")}", {}).status

    # Uploads that begin before either is finalized are compared again when each is published.
    accented = begin_upload(route("résumé.txt"))
    plain = begin_upload("resume.txt")
    listed = ->(part, bytes) { { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => put_part(part, bytes), "part" => 1 } ] } }
    assert_equal 201, api("POST", "/files/#{route("résumé.txt")}", listed.call(accented, "accented")).status
    assert_equal 501, api("POST", "/files/resume.txt", listed.call(plain, "plain")).status

    # The exact spelling still replaces its own file.
    assert_equal 200, upload("café.bin", [ "replaced" ]).status
    assert_equal [ "replaced", "accented" ], [ download("café.bin").body, download("résumé.txt").body ]
  end

  def test_other_unicode_names_keep_their_exact_spelling_and_stay_distinct
    # The API's comparison map keeps Cyrillic й and и, and Georgian Ა and ა, apart; lowercasing or
    # transliterating them would wrongly merge them.
    contents = { "й.txt" => "short i", "и.txt" => "i", "Ა.txt" => "mtavruli", "ა.txt" => "mkhedruli", "file….txt" => "ellipsis",
                 "¼½⅟⁄∕%.txt" => "fractions", "ＡＢＣ/Ünïcödé.txt" => "fullwidth folder", "Résumé.TXT" => "résumé" }
    contents.each do |path, content|
      created = upload(path, [ content ])
      assert_equal [ 201, path, path.split("/").last ], [ created.status, created.json["path"], created.json["display_name"] ], path
    end
    # A download is bytes, so compare bytes. Before Ruby 4.0, Rack's mock request also relabelled
    # each uploaded String as binary in place, which hid the difference.
    downloaded = contents.keys.to_h { |path| [ path, download(path).body ] }
    assert_equal contents.transform_values(&:b), downloaded
  end

  def test_path_comparison_gives_the_servers_shared_example_results
    comparison = FilesMockServer::Simulation::PathComparison.shared
    JSON.parse(File.read(File.join(APP_ROOT, "shared/comparison_examples.json"))).each do |path, key|
      assert_equal key, comparison.key(path), path.inspect
    end
  end

  def test_comparison_data_that_is_missing_or_another_version_is_refused
    Tempfile.create([ "path_comparison", ".json" ]) do |file|
      file.write(JSON.generate("version" => 2, "collation" => "utf8mb4_0900_ai_ci", "mapping" => {}))
      file.close
      error = assert_raises(ArgumentError) { FilesMockServer::Simulation::PathComparison.new(file.path) }
      assert_includes error.message, file.path
      assert_includes error.message, "not version 1"
    end
    assert_raises(ArgumentError) { FilesMockServer::Simulation::PathComparison.new(File.join(Dir.tmpdir, "no-such-path-comparison.json")) }
  end

  def test_unmodeled_parameters_actions_and_paths_fail_visibly_without_changes
    upload("folder/file.bin", [ "kept" ])
    part = begin_upload("new.bin")
    finalize = ->(params) { api("POST", "/files/new.bin", { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => put_part(part, "x"), "part" => 1 } ] }.merge(params)) }
    {
      "restart offset" => api("POST", "/file_actions/begin_upload/c.bin", { "restart" => 5 }),
      "rename instead of overwrite" => api("POST", "/file_actions/begin_upload/c.bin", { "with_rename" => true }),
      "a ref without a part" => api("POST", "/file_actions/begin_upload/new.bin", { "ref" => part["ref"] }),
      "another upload action" => api("POST", "/files/c.bin", { "action" => "append" }),
      "custom metadata" => finalize.call({ "custom_metadata" => { "k" => "v" } }),
      "a redirect download" => api("GET", "/files/folder/file.bin", { "action" => "redirect" }),
      "previews" => api("GET", "/file_actions/metadata/folder/file.bin", { "with_previews" => true }),
      "a leading slash" => api("POST", "/file_actions/begin_upload//c.bin", {}),
      "a dot segment" => api("POST", "/file_actions/begin_upload/folder/../c.bin", {}),
      "another spelling of a file" => api("POST", "/file_actions/begin_upload/Folder/File.bin", {}),
      "a file named like a folder" => api("POST", "/file_actions/begin_upload/folder", {}),
      "a file two levels inside a file" => api("POST", "/file_actions/begin_upload/folder/file.bin/inner/deeper.bin", {}),
    }.each do |name, response|
      assert_equal [ 501, "simulation/not-supported" ], [ response.status, response.json["type"] ], name
    end
    # The API refuses a file as the immediate parent folder.
    inside = api("POST", "/file_actions/begin_upload/folder/file.bin/inner.bin", {})
    assert_equal [ 422, "bad-request/folder-must-not-be-a-file" ], [ inside.status, inside.json["type"] ]
    head = transfer("HEAD", download_url("folder/file.bin"))
    assert_equal [ 501, "" ], [ head.status, head.body ]
    no_action = api("POST", "/files/new.bin", { "ref" => part["ref"] })
    assert_equal [ 422, "action is missing" ], [ no_action.status, no_action.json["error"] ]
    other_path = api("POST", "/file_actions/begin_upload/c.bin", { "path" => "d.bin" })
    assert_equal [ 422, "path must match the path in the URL" ], [ other_path.status, other_path.json["error"] ]
    assert_equal({ "uploads" => 1, "files" => 1, "bytes_in_use" => 5 }, control("GET", "ready").json["transfers"]["state"])
  end

  # The production schema documents begin_upload's and finalize_upload's size as int32, but the API
  # reads an upload's size as an Integer byte count, so both take the int64 range, 2 GiB and beyond.
  # Every other whole number keeps its schema's width, part numbers among them, a size must still be
  # a whole number and not negative, and the unmodeled restart and length are refused before any
  # conversion. A refusal changes nothing.
  def test_upload_sizes_take_the_int64_range_where_the_schema_documents_int32
    with_int32_upload_params do
      large = 2**31
      [ large, large.to_s, (2**63) - 1 ].each { |size| begin_upload("begun-#{size}.bin", { "size" => size }) }
      part = begin_upload("large.bin", { "size" => large })
      etags = [ { "etag" => put_part(part, "x"), "part" => 1 } ]
      finalize = ->(params) { api("POST", "/files/large.bin", { "action" => "end", "ref" => part["ref"], "etags" => etags }.merge(params)) }
      # The size is converted and reaches the check that the parts add up to it.
      unequal = finalize.call({ "size" => large })
      assert_equal [ 422, "bad-request/request-params-invalid", "Invalid request parameters: size is 2147483648, but the parts hold 1 bytes" ],
                   [ unequal.status, *unequal.json.values_at("type", "error") ]

      held = transfer_state
      {
        "a size beyond int64" => [ api("POST", "/file_actions/begin_upload/c.bin", { "size" => 2**63 }), 422, "bad-request", "size is invalid" ],
        "a negative size" => [ api("POST", "/file_actions/begin_upload/c.bin", { "size" => -1 }), 422, "bad-request", "size is invalid" ],
        "a size that is not a whole number" => [ api("POST", "/file_actions/begin_upload/c.bin", { "size" => "2147483648.5" }), 422, "bad-request", "size is invalid" ],
        "a part count beyond int32" => [ api("POST", "/file_actions/begin_upload/c.bin", { "parts" => large }), 422, "bad-request", "parts is invalid" ],
        "a part number beyond int32" => [ api("POST", "/file_actions/begin_upload/large.bin", { "ref" => part["ref"], "part" => large }), 422, "bad-request", "part is invalid" ],
        "a finalize size beyond int64" => [ finalize.call({ "size" => 2**63 }), 422, "bad-request", "size is invalid" ],
        "a restart offset" => [ api("POST", "/file_actions/begin_upload/c.bin", { "size" => large, "restart" => large }), 501, "simulation/not-supported",
                                "Simulation does not support these parameters: restart" ],
        "a finalize length" => [ finalize.call({ "size" => 1, "length" => large }), 501, "simulation/not-supported", "Simulation does not support these parameters: length" ],
      }.each do |name, (response, status, type, error)|
        assert_equal [ status, type, error ], [ response.status, *response.json.values_at("type", "error") ], name
      end
      assert_equal held, transfer_state
      assert_equal 201, finalize.call({ "size" => 1 }).status
    end
  end

  def test_upload_and_download_urls_use_the_configured_origin_and_never_guess_one
    configured = new_app(transfer_origin: "https://files.example:8443/")
    assert begin_upload("a.bin", to: configured)["upload_uri"].start_with?("https://files.example:8443/__files_mock/transfer/upload/")

    unconfigured = new_app(transfer_origin: nil)
    refused = api("POST", "/file_actions/begin_upload/a.bin", {}, to: unconfigured)
    assert_equal [ 501, 0 ], [ refused.status, control("GET", "ready", to: unconfigured).json["transfers"]["state"]["uploads"] ]
    assert_includes refused.json["error"], "FILES_MOCK_TRANSFER_ORIGIN"
    [ "ftp://files.example", "http://127.0.0.1:4041/mock", "127.0.0.1:4041", "http://user@127.0.0.1" ].each do |origin|
      assert_raises(ArgumentError, origin) { FilesMockServer::Simulation::App.new(transfer_origin: origin) }
    end
  end

  private

  # Runs the block against a simulator whose schema documents the upload sizes and the unmodeled
  # restart and length as int32, as the production schema does, whichever schema this server was
  # generated from.
  def with_int32_upload_params
    schema = JSON.parse(File.read(FilesMockServer::Simulation::SCHEMA_PATH))
    int32 = { "type" => "int64", "format" => "int32", "required" => false }
    schema["operations"]["files.begin_upload"]["params"].merge!("size" => int32, "restart" => int32)
    schema["operations"]["files.finalize_upload"]["params"].merge!("size" => int32, "restart" => int32, "length" => int32)
    Tempfile.create([ "schema", ".json" ]) do |file|
      file.write(JSON.generate(schema))
      file.close
      @app = Rack::Lint.new(FilesMockServer::Simulation::App.new(limits: FilesMockServer::Simulation::Limits.new, schema_path: file.path, transfer_origin: ORIGIN))
      yield
    end
  end

  # Uploads parts in order and finalizes without etags, as the .NET SDK does.
  def finalize_received(path, parts, params)
    first = begin_upload(route(path))
    parts.each_with_index { |bytes, index| put_part(index.zero? ? first : begin_upload(route(path), { "ref" => first["ref"], "part" => index + 1 }), bytes) }
    api("POST", "/files/#{route(path)}", { "action" => "end", "ref" => first["ref"] }.merge(params))
  end

  def finalize_and_download(path, first_part, etags)
    listed = etags.each_with_index.map { |etag, index| { "etag" => etag.delete('"'), "part" => index + 1 } }
    finalized = api("POST", "/files/#{route(path)}", { "action" => "end", "ref" => first_part["ref"], "etags" => listed })
    assert_operator finalized.status, :<, 300, finalized.body
    download(path).body
  end

  def download_url(path)
    api("GET", "/files/#{route(path)}").json.fetch("download_uri")
  end

  def read_and_close(body)
    content = +""
    body.each { |slice| content << slice }
    content
  ensure
    body.close
  end

  def begin_batch(route, params)
    response = api("POST", "/file_actions/begin_upload/#{route}", params)
    assert_equal 200, response.status, response.body
    response.json
  end

  def form(method, path, body, env = {}, to: app)
    request(to, method, "/api/rest/v1#{path}", body, { "CONTENT_TYPE" => "application/x-www-form-urlencoded; charset=utf-8" }.merge(env))
  end

  def transfer_state(to: app)
    control("GET", "ready", to:).json["transfers"]["state"]
  end

  def bytes_in_use(to: app)
    transfer_state(to:)["bytes_in_use"]
  end
end
