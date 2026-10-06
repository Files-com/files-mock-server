require_relative "test_helper"

# Upload and download profiles a reset chooses (Profile::Upload, Profile::Download).
# A part body of unknown length (no Content-Length), as a chunked request sends it.
class UnsizedBody < StringIO
  undef_method :size
end

# A part body of unknown length whose transport fails while it is read.
class AbortedBody < StringIO
  undef_method :size

  def read(*)
    raise IOError, "the client went away"
  end
end

class TransferProfilesTest < Minitest::Test
  include SimulationRequests
  include FileRequests

  # FileUploadPart fields the combined adaptive schema adds and the pinned production schema lacks.
  ADAPTIVE_PART_FIELDS = %w[part_offset_query variable_part_limits upload_target_class].freeze

  def setup
    @app = new_app
  end

  def test_the_legacy_profile_advertises_serial_parts_without_checking_them
    ready = control("GET", "ready").json
    assert_equal({ "mode" => "legacy", "retry_parts" => true, "partsize" => 1_048_576, "part_offset_query" => false }, ready.dig("profile", "upload"))
    assert_equal({ "http_method" => "PUT", "parallel_parts" => false, "retry_parts" => true, "partsize" => 1_048_576 }, ready.dig("transfers", "upload_parts"))
    first = begin_upload("f.bin")
    second = begin_upload("f.bin", { "ref" => first["ref"], "part" => 2 })
    put_part(second, "b")
    etags = [ { "etag" => put_part(first, "a"), "part" => 1 }, { "etag" => put_part(second, "b"), "part" => 2 } ]
    assert_equal 201, api("POST", "/files/f.bin", { "action" => "end", "ref" => first["ref"], "etags" => etags }).status
    refused = control("POST", "reset", { "profile" => { "upload" => { "retry_parts" => false } } })
    assert_equal [ 400, "profile.upload settings other than mode need mode serial or parallel" ], [ refused.status, refused.json["error"] ]
  end

  def test_a_serial_profile_admits_one_part_at_a_time_in_order_with_exact_part_sizes
    profile_reset({ "upload" => { "mode" => "serial", "partsize" => 4 } })
    first = begin_upload("f.bin")
    assert_equal [ false, true, 4, 4 ], first.values_at("parallel_parts", "retry_parts", "partsize", "next_partsize")
    second = begin_upload("f.bin", { "ref" => first["ref"], "part" => 2 })
    early = transfer("PUT", second["upload_uri"], "efgh")
    assert_equal [ 409, "simulation/profile-violation", "Part 2 was sent before part 1; the serial upload profile admits parts in order" ], [ early.status, *early.json.values_at("type", "error") ]

    # While part 1's body is still being read, part 2 is refused.
    during = nil
    body = InterruptedBody.new("abcd", -> { during = transfer("PUT", second["upload_uri"], "efgh") })
    assert_equal 200, raw_request(app, "PUT", URI(first["upload_uri"]).request_uri, body, {}).status
    assert_equal [ 409, "Part 1 of this upload is still being sent; the serial upload profile admits one part at a time" ], [ during.status, during.json["error"] ]
    etags = [ { "etag" => Digest::SHA256.hexdigest("abcd"), "part" => 1 }, { "etag" => put_part(second, "ef"), "part" => 2 } ]
    assert_equal 201, api("POST", "/files/f.bin", { "action" => "end", "ref" => first["ref"], "etags" => etags }).status

    # partsize is a hint, not a size parts must hold: parts larger and smaller than it are stored in
    # order, as clients that size parts their own way send them, and a part an injected 503 failed
    # is sent again with the same bytes before the upload finishes.
    add_fault({ "operation" => "transfers.upload_part", "match" => { "part" => 2 }, "status" => 503 })
    parts = [ begin_upload("g.bin") ]
    parts += (2..3).map { |number| begin_upload("g.bin", { "ref" => parts.first["ref"], "part" => number }) }
    assert_equal([ 4, 4, 4 ], parts.map { |part| part["partsize"] })
    etags = [ { "etag" => put_part(parts[0], "abcdefgh"), "part" => 1 } ]
    assert_equal 503, transfer("PUT", parts[1]["upload_uri"], "ij").status
    etags += [ { "etag" => put_part(parts[1], "ij"), "part" => 2 }, { "etag" => put_part(parts[2], "klmnop"), "part" => 3 } ]
    assert_equal 201, api("POST", "/files/g.bin", { "action" => "end", "ref" => parts.first["ref"], "etags" => etags, "size" => 16 }).status
    assert_equal "abcdefghijklmnop", download("g.bin").body
    assert_equal [ [ 1, 200, 8 ], [ 2, 503, nil ], [ 2, 200, 2 ], [ 3, 200, 6 ] ], journaled("transfers.upload_part", %w[part status bytes]).last(4)

    # An exact boundary may end with an empty part, and an empty file is one empty part.
    assert_equal 201, upload("h.bin", [ "abcd", "efgh", "" ]).status
    assert_equal "abcdefgh", download("h.bin").body
    assert_equal [ 201, "" ], [ upload("empty.bin", [ "" ]).status, download("empty.bin").body ]
  end

  def test_a_parallel_profile_admits_parts_in_any_order_up_to_a_shared_concurrency_limit
    simulation = FilesMockServer::Simulation::App.new(limits: FilesMockServer::Simulation::Limits.new, transfer_origin: ORIGIN)
    @app = Rack::Lint.new(simulation)
    profile_reset({ "upload" => { "mode" => "parallel", "partsize" => 2, "max_concurrent_parts" => 1, "throttle_retry_after" => 2 } })
    assert_equal({ "in_flight" => 0, "most_in_flight" => 0 }, upload_parts, "a reset starts the count")
    first = begin_upload("a.bin")
    assert_equal true, first["parallel_parts"]
    other = begin_upload("b.bin")
    throttled = nil
    body = InterruptedBody.new("cd", -> { throttled = transfer("PUT", other["upload_uri"], "zz") })
    second = begin_upload("a.bin", { "ref" => first["ref"], "part" => 2 })
    assert_equal 200, raw_request(app, "PUT", URI(second["upload_uri"]).request_uri, body, {}).status
    assert_equal [ 503, "2" ], [ throttled.status, throttled.headers["retry-after"] ], "the profile's one place is shared across uploads, so another upload's part is refused"
    assert_equal "simulation/profile-violation", throttled.json["type"]
    etags = [ { "etag" => put_part(first, "ab"), "part" => 1 }, { "etag" => Digest::SHA256.hexdigest("cd"), "part" => 2 } ]
    assert_equal 201, api("POST", "/files/a.bin", { "action" => "end", "ref" => first["ref"], "etags" => etags }).status
    assert_equal "abcd", download("a.bin").body
    # The throttled send held nothing, and the other upload can still send its part. The journal
    # lists requests as they finish, so the throttled send comes before the one it overlapped.
    put_part(other, "zz")
    assert_equal [ [ 503, "b.bin" ], [ 200, "a.bin" ], [ 200, "a.bin" ], [ 200, "b.bin" ] ], upload_parts_journal
    assert_equal({ "in_flight" => 0, "most_in_flight" => 1 }, upload_parts)

    # A part keeps its place until it has been applied, not only while its body is read. This app's
    # delay waits until the test lets the delayed part go on: while it waits before it is applied,
    # another part is refused, and once it is stored the other is admitted.
    at_wait = Queue.new
    go_on = Queue.new
    simulation.define_singleton_method(:wait_before_applying) do |_fault|
      at_wait << true
      raise "the delayed part was not let go on within 10s" unless go_on.pop(timeout: 10)
    end
    held_part = begin_upload("c.bin")
    waiting = begin_upload("d.bin")
    add_fault({ "operation" => "transfers.upload_part", "match" => { "path" => "c.bin" }, "kind" => "delay", "delay_ms" => 2_000 })
    held = Thread.new { transfer("PUT", held_part["upload_uri"], "cc") }
    begin
      assert at_wait.pop(timeout: 10), "the delayed part reached its wait before it is applied"
      assert_equal({ "in_flight" => 1, "most_in_flight" => 1 }, upload_parts, "the waiting part still holds its place")
      refused = transfer("PUT", waiting["upload_uri"], "dd")
      assert_equal [ 503, "2" ], [ refused.status, refused.headers["retry-after"] ]
    ensure
      go_on << true
      finished = held.join(10)
    end
    assert finished, "the delayed part finished within 10s of being let go on"
    assert_equal 200, held.value.status
    assert_equal({ "in_flight" => 0, "most_in_flight" => 1 }, upload_parts, "the stored part gave its place back")
    assert_equal 200, transfer("PUT", waiting["upload_uri"], "dd").status
    assert_equal({ "in_flight" => 0, "most_in_flight" => 1 }, upload_parts, "never more than the profile's one place")
  end

  def test_a_profile_that_forbids_retries_refuses_a_second_send_of_a_part
    profile_reset({ "upload" => { "mode" => "serial", "retry_parts" => false, "partsize" => 3 } })
    part = begin_upload("f.bin")
    assert_equal false, part["retry_parts"]
    put_part(part, "abc")
    again = transfer("PUT", part["upload_uri"], "abc")
    assert_equal [ 409, "Part 1 was already sent; the upload profile does not allow retrying parts, so restart the upload" ], [ again.status, again.json["error"] ]
  end

  # A part keeps the length it was first sent with through a fault, a retry and a renewed URL. A
  # declared Content-Length binds it before the body is read; a body of unknown length binds it once
  # it has been read in full. A prefix the transport cut short binds nothing, and the last part may
  # still be short.
  def test_a_part_keeps_its_intended_length_through_faults_retries_and_renewal
    profile_reset({ "upload" => { "mode" => "serial", "partsize" => 4 } })
    part = begin_upload("f.bin")
    add_fault({ "operation" => "transfers.upload_part", "match" => { "part" => 1 }, "status" => 503 })
    assert_equal 503, transfer("PUT", part["upload_uri"], "abcd").status
    renewed = begin_upload("f.bin", { "ref" => part["ref"], "part" => 1 })
    replanned = transfer("PUT", renewed["upload_uri"], "ab")
    assert_equal [ 409, "Part 1 was first sent with 4 bytes and is now sent with 2; every send of a part must carry the same bytes" ], [ replanned.status, replanned.json["error"] ]
    assert_equal 200, transfer("PUT", renewed["upload_uri"], "abcd").status

    second = begin_upload("f.bin", { "ref" => part["ref"], "part" => 2 })
    unknown = raw_request(app, "PUT", URI(second["upload_uri"]).request_uri, UnsizedBody.new("ef"), {})
    assert_equal 200, unknown.status
    retried = transfer("PUT", second["upload_uri"], "efg")
    assert_equal [ 409, "Part 2 was first sent with 2 bytes and is now sent with 3; every send of a part must carry the same bytes" ], [ retried.status, retried.json["error"] ]
    etags = [ { "etag" => Digest::SHA256.hexdigest("abcd"), "part" => 1 }, { "etag" => Digest::SHA256.hexdigest("ef"), "part" => 2 } ]
    assert_equal 201, api("POST", "/files/f.bin", { "action" => "end", "ref" => part["ref"], "etags" => etags }).status

    cut = begin_upload("g.bin")
    assert_raises(IOError) { raw_request(app, "PUT", URI(cut["upload_uri"]).request_uri, AbortedBody.new("abc"), {}) }
    assert_equal 200, transfer("PUT", cut["upload_uri"], "wxyz").status
  end

  # partsize_changes changes the partsize of later parts only: each part keeps the partsize it was
  # issued with, and next_partsize announces the next one.
  def test_partsize_changes_affect_only_parts_not_yet_issued
    profile_reset({ "upload" => { "mode" => "parallel", "partsize" => 4, "partsize_changes" => [ { "from_part" => 3, "partsize" => 6 } ] } })
    first = begin_upload("f.bin")
    parts = [ first ] + (2..4).map { |number| begin_upload("f.bin", { "ref" => first["ref"], "part" => number }) }
    assert_equal([ [ 4, 4 ], [ 4, 6 ], [ 6, 6 ], [ 6, 6 ] ], parts.map { |part| part.values_at("partsize", "next_partsize") })
    assert_equal 4, begin_upload("f.bin", { "ref" => first["ref"], "part" => 2 })["partsize"], "a renewed URL keeps its partsize"
    # A batch issues each part as a single begin_upload would, and renewing a range keeps each part's.
    batch = api("POST", "/file_actions/begin_upload/h.bin", { "parts" => 2 }).json
    renewed = api("POST", "/file_actions/begin_upload/h.bin", { "ref" => batch.first["ref"], "part" => 2, "parts" => 3 }).json
    assert_equal([ [ 1, 4, 4 ], [ 2, 4, 6 ], [ 2, 4, 6 ], [ 3, 6, 6 ], [ 4, 6, 6 ] ], (batch + renewed).map { |part| part.values_at("part_number", "partsize", "next_partsize") })
    bytes = %w[abcd efgh ijklmn op]
    etags = parts.zip(bytes).each_with_index.map { |(part, data), index| { "etag" => put_part(part, data), "part" => index + 1 } }
    assert_equal 201, api("POST", "/files/f.bin", { "action" => "end", "ref" => first["ref"], "etags" => etags }).status
    assert_equal bytes.join, download("f.bin").body
    assert_equal 400, control("POST", "reset", { "profile" => { "upload" => { "mode" => "serial", "partsize_changes" => [ { "from_part" => 1, "partsize" => 6 } ] } } }).status
  end

  # A part body the client abandons releases its bytes and its place, so the next send is admitted.
  def test_an_abandoned_part_releases_its_bytes_and_admission
    profile_reset({ "upload" => { "mode" => "serial", "partsize" => 4 } })
    part = begin_upload("f.bin")
    broken = Object.new
    def broken.read(*) = raise(IOError, "client went away")
    def broken.gets = nil
    def broken.each = nil
    def broken.rewind = nil
    assert_raises(IOError) { raw_request(app, "PUT", URI(part["upload_uri"]).request_uri, broken, { "CONTENT_LENGTH" => "4" }) }
    assert_equal 0, control("GET", "ready").json.dig("transfers", "state", "bytes_in_use")
    assert_equal({ "in_flight" => 0, "most_in_flight" => 1 }, upload_parts, "the abandoned part held one place and gave it back")
    put_part(part, "abcd")
    assert_equal({ "in_flight" => 0, "most_in_flight" => 1 }, upload_parts)
  end

  def test_profiles_advertising_adaptive_fields_need_a_schema_that_declares_them
    @app = schema_app { |part_fields| part_fields - ADAPTIVE_PART_FIELDS }
    refused = control("POST", "reset", { "profile" => { "upload" => { "mode" => "parallel", "part_offset_query" => true } } })
    assert_equal [ 400, "simulation/invalid-control-request" ], [ refused.status, refused.json["type"] ]
    assert_match(/does not declare FileUploadPart part_offset_query/, refused.json["error"])
    @app = adaptive_app
    profile_reset({ "upload" => { "mode" => "parallel", "part_offset_query" => true, "partsize" => 4, "upload_target_class" => "agent_fiw" } })
    assert_equal [ true, "agent_fiw" ], begin_upload("f.bin").values_at("part_offset_query", "upload_target_class")

    # Each setting needs only its own field: a schema with some of the fields accepts exactly the
    # profiles that advertise those, alone or together.
    settings = { "part_offset_query" => true, "variable_part_limits" => { "min_nonfinal_bytes" => 3, "max_part_bytes" => 6, "max_parts" => 3, "max_file_bytes" => 12 },
                 "upload_target_class" => "s3" }
    [ [], %w[part_offset_query], %w[variable_part_limits], %w[upload_target_class], %w[part_offset_query variable_part_limits], ADAPTIVE_PART_FIELDS ].each do |declared|
      @app = schema_app { |part_fields| (part_fields - ADAPTIVE_PART_FIELDS) | declared }
      [ *settings.keys.map { |field| [ field ] }, %w[part_offset_query variable_part_limits], settings.keys ].each do |advertised|
        response = control("POST", "reset", { "profile" => { "upload" => { "mode" => "parallel" }.merge(settings.slice(*advertised)) } })
        assert_equal (advertised - declared).empty? ? 200 : 400, response.status, "#{declared} advertising #{advertised}: #{response.body}"
      end
    end
  end

  # Offsets name each part's place in the file: every send of a part names the same one, and at
  # finalize they must match the sizes of the parts before.
  def test_part_offsets_are_immutable_and_must_match_the_parts_before
    @app = adaptive_app
    refused = transfer("PUT", "#{begin_upload("x.bin")["upload_uri"]}?part_offset=0", "a")
    assert_equal [ 501, "part_offset is accepted only when the upload profile advertises part_offset_query" ], [ refused.status, refused.json["error"] ]
    profile_reset({ "upload" => { "mode" => "parallel", "part_offset_query" => true, "partsize" => 4 } })
    first = begin_upload("f.bin")
    second = begin_upload("f.bin", { "ref" => first["ref"], "part" => 2 })
    second_etag = put_part({ "upload_uri" => "#{second["upload_uri"]}?part_offset=4" }, "ef")
    moved = transfer("PUT", "#{second["upload_uri"]}?part_offset=5", "ef")
    assert_equal [ 409, "Part 2 was first sent with part_offset 4; every send of a part must name the same offset" ], [ moved.status, moved.json["error"] ]
    first_etag = put_part({ "upload_uri" => "#{first["upload_uri"]}?part_offset=0" }, "abcd")
    etags = [ { "etag" => second_etag, "part" => 2 }, { "etag" => first_etag, "part" => 1 } ]
    assert_equal 201, api("POST", "/files/f.bin", { "action" => "end", "ref" => first["ref"], "etags" => etags }).status
    assert_equal "abcdef", download("f.bin").body

    wrong = begin_upload("g.bin")
    later = begin_upload("g.bin", { "ref" => wrong["ref"], "part" => 2 })
    etags = [ { "etag" => put_part({ "upload_uri" => "#{wrong["upload_uri"]}?part_offset=0" }, "abcd"), "part" => 1 },
              { "etag" => put_part({ "upload_uri" => "#{later["upload_uri"]}?part_offset=3" }, "e"), "part" => 2 } ]
    refused = api("POST", "/files/g.bin", { "action" => "end", "ref" => wrong["ref"], "etags" => etags })
    assert_equal [ 422, "Part 2 was sent with part_offset 3, but the parts before it hold 4 bytes" ], [ refused.status, refused.json["error"] ]
  end

  def test_variable_part_limits_allow_unequal_parts_within_them
    @app = adaptive_app
    limits = { "min_nonfinal_bytes" => 3, "max_part_bytes" => 6, "max_parts" => 3, "max_file_bytes" => 12 }
    profile_reset({ "upload" => { "mode" => "parallel", "variable_part_limits" => limits } })
    assert_equal limits, begin_upload("probe.bin")["variable_part_limits"]
    assert_equal 201, upload("ok.bin", %w[abcde fgh i], finalize: { "size" => 9 }).status
    assert_equal "abcdefghi", download("ok.bin").body
    {
      "a short part before the last" => [ %w[ab cdefg], { "size" => 7 }, "Part 1 holds fewer than min_nonfinal_bytes (3) and is not the last part" ],
      "too many parts" => [ %w[abc def ghi j], { "size" => 10 }, "The upload has 4 parts; the upload profile allows at most 3" ],
      "no final size for an upload begun without one" => [ %w[abc], {}, "An upload begun without size needs its final size and the etags of every part to finish" ],
    }.each do |name, (parts, finalize, error)|
      response = upload("#{name}.bin", parts, finalize:)
      assert_equal [ 422, error ], [ response.status, response.json["error"] ], name
    end
    large = transfer("PUT", begin_upload("large.bin")["upload_uri"], "abcdefg")
    assert_equal [ 422, "Part 1 declares 7 bytes; the upload profile allows at most 6 per part" ], [ large.status, large.json["error"] ]
  end

  def test_download_identity_follows_the_contract_under_its_profile
    upload("f.bin", [ "abc" ])
    legacy = api("GET", "/files/f.bin", { "with_download_identity" => true })
    refute legacy.json.key?("download_identity"), "the site's download identity setting is off by default"

    profile_reset({ "download" => { "identity" => "contract_v1" }, "upload" => { "mode" => "legacy" } })
    upload("f.bin", [ "abc" ])
    negotiated = api("GET", "/files/f.bin", { "with_download_identity" => true })
    identity = negotiated.json["download_identity"]
    # The Python SDK sends the flag as "True" or "False" in the query string.
    assert_equal identity, api("GET", "/files/f.bin", { "with_download_identity" => "True" }).json["download_identity"]
    assert_equal([ 200, false ], api("GET", "/files/f.bin", { "with_download_identity" => "False" }).then { |response| [ response.status, response.json.key?("download_identity") ] })
    assert_equal [ 1, 3, { "If-Match" => %("#{Digest::SHA256.hexdigest("abc")}") } ], identity.values_at("version", "size", "required_headers")
    assert_match(/\Afdi1\.[A-Za-z0-9_-]+\z/, identity["token"])
    url = negotiated.json["download_uri"]
    assert_equal([ 200, "abc" ], transfer("GET", url, nil, { "HTTP_IF_MATCH" => identity["required_headers"]["If-Match"] }).then { |response| [ response.status, response.body ] })
    ranged = transfer("GET", url, nil, { "HTTP_IF_MATCH" => identity["required_headers"]["If-Match"], "HTTP_RANGE" => "bytes=1-" })
    assert_equal [ 206, "bytes 1-2/3", "bc" ], [ ranged.status, ranged.headers["content-range"], ranged.body ]
    assert_equal 400, transfer("GET", url).status
    assert_equal([ 412, "download_source_changed" ], transfer("GET", url, nil, { "HTTP_IF_MATCH" => %("other") }).then { |response| [ response.status, response.json["type"] ] })

    renewed = api("GET", "/files/f.bin", { "expected_download_identity" => identity["token"] })
    assert_equal identity, renewed.json["download_identity"]
    # A replacement of the same size is a change: renewal is unavailable and the old URL is stale.
    upload("f.bin", [ "xyz" ])
    stale = api("GET", "/files/f.bin", { "expected_download_identity" => identity["token"] })
    assert_equal [ 422, "processing-failure/download-identity-unavailable" ], [ stale.status, stale.json["type"] ]
    assert_equal 412, transfer("GET", url, nil, { "HTTP_IF_MATCH" => identity["required_headers"]["If-Match"] }).status

    upload("g.bin", [ "abc" ])
    api("POST", "/folders/dir", {})
    {
      "another file's token" => [ api("GET", "/files/g.bin", { "expected_download_identity" => identity["token"] }), 422, "processing-failure/download-identity-unavailable" ],
      "a token that is not fdi1" => [ api("GET", "/files/f.bin", { "expected_download_identity" => "v1.forged" }), 400, "bad-request/request-params-invalid" ],
      "stat" => [ api("GET", "/files/f.bin", { "action" => "stat", "with_download_identity" => true }), 400, "bad-request/request-params-invalid" ],
      "a folder" => [ api("GET", "/files/dir", { "with_download_identity" => true }), 400, "bad-request/request-params-invalid" ],
      "false with a token" => [ api("GET", "/files/f.bin", { "with_download_identity" => false, "expected_download_identity" => identity["token"] }), 400, "bad-request/request-params-invalid" ],
      "False with a token" => [ api("GET", "/files/f.bin", { "with_download_identity" => "False", "expected_download_identity" => identity["token"] }), 400, "bad-request/request-params-invalid" ],
      # Where the schema declares the flag (the local export), its type check refuses it first.
      "a flag that is not a boolean" => [ api("GET", "/files/f.bin", { "with_download_identity" => "TRUE" }), *(identity_declared? ? [ 422, "bad-request" ] : [ 400, "bad-request/request-params-invalid" ]) ],
    }.each do |name, (response, status, type)|
      assert_equal [ status, type ], [ response.status, response.json["type"] ], name
    end
  end

  # Where the schema declares the identity parameters (the local export b8129459), the "absent"
  # profile is the site setting off: an ordinary download, and 422 for a renewal (fail closed).
  def test_identity_parameters_declared_by_the_schema_follow_the_setting_off_rules
    @app = schema_app(identity: true) { |part_fields| part_fields }
    upload("f.bin", [ "abc" ])
    ordinary = api("GET", "/files/f.bin", { "with_download_identity" => true })
    assert_equal [ 200, false ], [ ordinary.status, ordinary.json.key?("download_identity") ]
    assert_equal([ 200, false ], api("GET", "/files/f.bin", { "with_download_identity" => "True" }).then { |response| [ response.status, response.json.key?("download_identity") ] })
    renewal = api("GET", "/files/f.bin", { "expected_download_identity" => "fdi1.abc" })
    assert_equal [ 422, "processing-failure/download-identity-unavailable" ], [ renewal.status, renewal.json["type"] ]
    assert_equal 400, api("GET", "/files/f.bin", { "expected_download_identity" => "not a token" }).status
  end

  # Presigned URLs are sent back byte for byte: any change to the query is refused as a storage
  # provider refuses it, and the sentinel credential is all that identifies the signer.
  def test_signed_urls_must_be_sent_with_their_exact_query
    profile_reset({ "signed_urls" => { "lifetime" => 600 } })
    part = begin_upload("f.bin")
    query = URI(part["upload_uri"]).query
    assert_match(/\AX-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=SIMULATEDSENTINELKEY%2F\d{8}%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=\d{8}T\d{6}Z&X-Amz-Expires=600&X-Amz-SignedHeaders=host&X-Amz-Signature=\h{64}\z/, query)
    {
      "a decoded slash" => part["upload_uri"].sub("%2F", "/"),
      "reordered parameters" => part["upload_uri"].sub(/\?([^&]+)&([^&]+)/, '?\2&\1'),
      "no query" => part["upload_uri"].split("?").first,
    }.each do |name, url|
      refused = transfer("PUT", url, "abc")
      assert_equal [ 403, "application/xml" ], [ refused.status, refused.headers["content-type"] ], name
      assert_match(/<Code>(SignatureDoesNotMatch|AccessDenied)<\/Code>/, refused.body, name)
    end
    etag = put_part(part, "abc")
    assert_equal 201, api("POST", "/files/f.bin", { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => etag, "part" => 1 } ] }).status
    url = api("GET", "/files/f.bin").json["download_uri"]
    assert_equal([ 200, "abc" ], transfer("GET", url).then { |response| [ response.status, response.body ] })
    # One signature digit changed (a digit that is already 0 becomes 1).
    assert_equal 403, transfer("GET", url.sub(/Signature=(\h)/) { "Signature=#{Regexp.last_match(1) == "0" ? "1" : "0"}" }).status
    @app = adaptive_app
    combined = control("POST", "reset", { "profile" => { "signed_urls" => {}, "upload" => { "mode" => "parallel", "part_offset_query" => true } } })
    assert_equal 400, combined.status
  end

  # Under request_status a successful storage download carries its request ID and download ID, as the
  # historical Files Sync Worker's did, and the download URL joined with the ID (the Go SDK's
  # DownloadRequestStatus) answers 200 with that producer's envelope whatever the status: http_code,
  # nulls kept, no timestamps, the bytes of the version the response was made from (none while
  # started), and for failed and error the error the request holds.
  def test_a_download_request_status_answers_the_historical_envelope_at_the_joined_url
    %w[completed started failed error].each do |status|
      profile_reset({ "download" => { "request_status" => { "status" => status } } })
      upload("f.bin", [ "abcdef" ])
      url = api("GET", "/files/f.bin").json["download_uri"]
      code = URI(url).path.split("/").last
      [ [ {}, 200, 6 ], [ { "HTTP_RANGE" => "bytes=2-3" }, 206, 2 ] ].each do |env, http_status, bytes|
        download = transfer("GET", url, nil, env)
        id = download.headers["x-files-download-request-id"]
        assert_equal [ http_status, code ], [ download.status, download.headers["x-files-download-id"] ], status
        answer = transfer("GET", "#{url}/#{id}")
        body = answer.json
        data = { "file_download_id" => code, "request_id" => id, "id" => id, "type" => "file_download", "bytes_transferred" => (bytes unless status == "started"),
                 "file_transfer_id" => code, "status" => status, "method" => "get" }
        assert_equal [ 200, "application/json", %w[data error errors http_code title type], [ nil, 200, nil ], data ],
                     [ answer.status, answer.headers["content-type"], body.keys.sort, body.values_at("title", "http_code", "errors"), body["data"] ], status
        if %w[failed error].include?(status)
          assert_equal "download_error", body["type"], status
          refute_empty body["error"], "a Go client reads an empty error as no error"
        else
          assert_equal [ nil, nil ], body.values_at("type", "error"), status
        end
      end
      assert_equal [ [ 200, 1, 6 ], [ 206, 2, 2 ] ], journaled("transfers.download", %w[status download_request bytes]), status
      assert_equal [ [ 200, 1, 1, "found" ], [ 200, 1, 2, "found" ] ], journaled("transfers.download_status", %w[status version download_request download_request_lookup]), status
    end
  end

  # The producer found a request by its ID and then required the transfer the URL names: an ID
  # answers at another download URL of the reset too, naming both, while an ID never issued, a
  # malformed one, another simulator's, a known ID at a URL that names no download, one whose request
  # newer ones displaced and one from before a reset each get 404 download_request_not_found. A reset
  # holds the newest FILES_MOCK_MAX_RECORDS requests; downloads go on beyond that.
  def test_download_request_ids_are_found_by_id_in_their_reset_and_the_newest_are_kept
    @app = new_app(max_records: 2)
    other = new_app
    profile_reset({ "download" => { "request_status" => {} } })
    other_reset = { "profile" => { "download" => { "request_status" => {} } }, "fixtures" => { "files" => [ { "path" => "o.bin", "text" => "o" } ] } }
    assert_equal 200, control("POST", "reset", other_reset, to: other).status
    upload("f.bin", [ "abc" ])
    upload("g.bin", [ "wxyz" ])
    f_url, g_url = %w[f g].map { |name| api("GET", "/files/#{name}.bin").json["download_uri"] }
    f_code, g_code = [ f_url, g_url ].map { |url| URI(url).path.split("/").last }
    f_id, g_id = [ f_url, g_url ].map { |url| transfer("GET", url).headers["x-files-download-request-id"] }
    other_id = transfer("GET", api("GET", "/files/o.bin", to: other).json["download_uri"], to: other).headers["x-files-download-request-id"]

    at_g = transfer("GET", "#{g_url}/#{f_id}")
    assert_equal [ 200, g_code, f_id, f_code, 3 ], [ at_g.status, *at_g.json["data"].values_at("file_download_id", "request_id", "file_transfer_id", "bytes_transferred") ]
    no_download = "#{f_url.sub(f_code, "00")}/#{g_id}"
    missing = [ "#{f_url}/#{f_id.sub(/\h\z/) { |digit| digit == "0" ? "1" : "0" }}", "#{f_url}/not-an-id", "#{f_url}/#{other_id}", no_download ]
    missing.each { |url| assert_not_found(transfer("GET", url), url == no_download ? "00" : f_code, url == no_download ? g_id : nil) }
    transfer("GET", f_url)
    assert_not_found(transfer("GET", "#{f_url}/#{f_id}"), f_code, nil)
    assert_equal %w[found_for_other_url not_issued not_issued not_issued no_transfer evicted], journaled("transfers.download_status", %w[download_request_lookup]).flatten
    assert_equal [ 3, 2, 2 ], control("GET", "ready").json.dig("transfers", "download_request_status").values_at("issued", "held", "max_held")

    profile_reset({ "download" => { "request_status" => {} } })
    upload("f.bin", [ "abc" ])
    new_url = api("GET", "/files/f.bin").json["download_uri"]
    assert_not_found(transfer("GET", "#{new_url}/#{g_id}"), URI(new_url).path.split("/").last, nil)
    assert_equal [ [ "earlier_reset" ] ], journaled("transfers.download_status", %w[download_request_lookup])
    assert_equal [ 0, 0 ], control("GET", "ready").json.dig("transfers", "download_request_status").values_at("issued", "held")
  end

  # A status lookup answers only at a download URL files.download issued in the reset, as the producer
  # answered only for a transfer it held: a request found by its ID gets 404 at a well-formed URL of
  # this simulator and reset for a version never made, and for one whose URL was never issued. An
  # issued URL keeps answering after its file is replaced, and a reset keeps the newest
  # FILES_MOCK_MAX_RECORDS issued URLs.
  def test_a_status_lookup_answers_only_at_a_download_url_the_reset_issued
    @app = new_app(max_records: 2)
    profile_reset({ "download" => { "request_status" => {} } })
    upload("f.bin", [ "abc" ])
    upload("g.bin", [ "wxyz" ])
    f_url = api("GET", "/files/f.bin").json["download_uri"]
    f_code = URI(f_url).path.split("/").last
    id = transfer("GET", f_url).headers["x-files-download-request-id"]
    # g.bin's version exists, but files.download has not issued its URL yet.
    [ with_version(f_code, 999_999), with_version(f_code, 2) ].each { |code| assert_not_found(transfer("GET", "#{f_url.sub(f_code, code)}/#{id}"), code, id) }

    upload("f.bin", [ "new" ])
    replaced = transfer("GET", "#{f_url}/#{id}")
    assert_equal [ 200, f_code, "completed", 3 ], [ replaced.status, *replaced.json["data"].values_at("file_download_id", "status", "bytes_transferred") ]
    g_url = api("GET", "/files/g.bin").json["download_uri"]
    other = transfer("GET", "#{g_url}/#{id}")
    assert_equal [ 200, URI(g_url).path.split("/").last, f_code ], [ other.status, *other.json["data"].values_at("file_download_id", "file_transfer_id") ]
    # A third issued URL displaces the oldest, f.bin's first one.
    api("GET", "/files/f.bin")
    assert_not_found(transfer("GET", "#{f_url}/#{id}"), f_code, id)
    assert_equal %w[no_transfer no_transfer found found_for_other_url no_transfer], journaled("transfers.download_status", %w[download_request_lookup]).flatten
    assert_equal [ 1, 2, 2 ], control("GET", "ready").json.dig("transfers", "download_request_status").values_at("held", "transfers_held", "max_held")
  end

  # The captured producer source set the request ID only when a GET began streaming, so these early
  # failures carry none: an injected error, a range past the end, a changed file's 409 and a fault's
  # own answer. header_on_failure gives each failed response one anyway, whose request read no
  # bytes; a fault's answer still has none.
  def test_only_a_successful_storage_download_gets_an_id_unless_header_on_failure_is_chosen
    [ false, true ].each do |header_on_failure|
      profile_reset({ "download" => { "request_status" => { "status" => "failed", "header_on_failure" => header_on_failure } } })
      upload("f.bin", [ "abc" ])
      url = api("GET", "/files/f.bin").json["download_uri"]
      add_fault({ "operation" => "transfers.download", "status" => 503 })
      injected = transfer("GET", url)
      past_end = transfer("GET", url, nil, { "HTTP_RANGE" => "bytes=9-" })
      add_fault({ "operation" => "transfers.download", "kind" => "html_page" })
      page = transfer("GET", url)
      upload("f.bin", [ "new" ])
      changed = transfer("GET", url)
      assert_equal [ [ 503, 416, 409 ], 200, nil ], [ [ injected, past_end, changed ].map(&:status), page.status, page.headers["x-files-download-request-id"] ]
      ids = [ injected, past_end, changed ].map { |response| response.headers["x-files-download-request-id"] }
      unless header_on_failure
        assert_equal [ nil, nil, nil ], ids
        next
      end

      ids.each do |id|
        answer = transfer("GET", "#{url}/#{id}")
        assert_equal [ 200, "download_error", "failed", nil ], [ answer.status, answer.json["type"], *answer.json["data"].values_at("status", "bytes_transferred") ]
      end
    end
  end

  # Without request_status nothing changes: no ID headers, the joined path is not simulated (501 with
  # no operation in the journal), and readiness reports nothing selected.
  def test_without_request_status_downloads_and_the_joined_path_are_unchanged
    upload("f.bin", [ "abc" ])
    url = api("GET", "/files/f.bin").json["download_uri"]
    download = transfer("GET", url)
    assert_equal [ 200, "abc", nil, nil ], [ download.status, download.body, download.headers["x-files-download-request-id"], download.headers["x-files-download-id"] ]
    joined = transfer("GET", "#{url}/0123")
    assert_equal [ 501, "simulation/not-supported" ], [ joined.status, joined.json["type"] ]
    assert_nil journal.last["operation"]
    ready = control("GET", "ready").json
    assert_equal [ { "identity" => "absent" }, nil, %w[transfers.upload_part transfers.download] ],
                 [ ready.dig("profile", "download"), ready.dig("transfers", "download_request_status", "selected"), ready.dig("transfers", "operations").map { |operation| operation["id"] } ]
  end

  # request_status takes a status and header_on_failure, and nothing else.
  def test_a_request_status_profile_is_checked
    [ { "status" => "done" }, { "header_on_failure" => "yes" }, { "on_failure" => true }, [] ].each do |spec|
      response = control("POST", "reset", { "profile" => { "download" => { "request_status" => spec } } })
      assert_equal [ 400, "simulation/invalid-control-request" ], [ response.status, response.json["type"] ], spec.inspect
    end
    profile_reset({ "download" => { "request_status" => {} } })
    assert_equal({ "identity" => "absent", "request_status" => { "status" => "completed", "header_on_failure" => false } }, control("GET", "ready").json.dig("profile", "download"))
  end

  # A withheld size sends a whole file without Content-Length and a range with an unknown total, as a
  # remote mount whose size cannot be trusted answers; the bytes are the same.
  def test_a_withheld_size_sends_no_length_and_an_unknown_range_total
    profile_reset({ "download" => { "size" => "withheld" } })
    upload("f.bin", [ "abcdef" ])
    url = api("GET", "/files/f.bin").json["download_uri"]
    whole = transfer("GET", url)
    ranged = transfer("GET", url, nil, { "HTTP_RANGE" => "bytes=1-2" })
    assert_equal [ 200, "abcdef", nil ], [ whole.status, whole.body, whole.headers["content-length"] ]
    assert_equal [ 206, "bc", "bytes 1-2/*", "2" ], [ ranged.status, ranged.body, ranged.headers["content-range"], ranged.headers["content-length"] ]
  end

  # The producer skipped its expiry check for a status lookup, so the joined path answers whatever
  # query comes with it: the download URL's own, as url.JoinPath keeps it, none or a changed one. The
  # download URL itself still checks its query.
  def test_the_status_lookup_does_not_check_the_download_urls_query
    profile_reset({ "signed_urls" => {}, "download" => { "request_status" => {} } })
    upload("f.bin", [ "abc" ])
    url = api("GET", "/files/f.bin").json["download_uri"]
    id = transfer("GET", url).headers.fetch("x-files-download-request-id")
    base, query = url.split("?", 2)
    changed = query.sub(/Signature=(\h)/) { "Signature=#{Regexp.last_match(1) == "0" ? "1" : "0"}" }
    answers = [ "#{base}/#{id}?#{query}", "#{base}/#{id}", "#{base}/#{id}?#{changed}" ].map { |lookup| transfer("GET", lookup).then { |answer| [ answer.status, answer.json.dig("data", "status") ] } }
    assert_equal [ [ 200, "completed" ] ] * 3, answers
    assert_equal 403, transfer("GET", "#{base}?#{changed}").status
  end

  private

  def upload_parts_journal
    paths = journaled("files.begin_upload", %w[upload path]).to_h.transform_values { |path| File.basename(path) }
    journaled("transfers.upload_part", %w[status upload]).map { |status, upload| [ status, paths.fetch(upload) ] }
  end

  # The journal's count of parts holding a place now and the most that held one at once.
  def upload_parts
    control("GET", "journal").json["upload_parts"]
  end

  # Whether this server's own schema declares the download identity parameters: the local export
  # b8129459 does, the production pin does not.
  def identity_declared?
    JSON.parse(File.read(FilesMockServer::Simulation::SCHEMA_PATH)).dig("operations", "files.download", "params").key?("with_download_identity")
  end

  # The historical producer's 404 for a request ID or download URL it does not hold, naming the URL's
  # download and the request found by ID, if any.
  def assert_not_found(response, code, request_id)
    error = { "type" => "download_request_not_found", "title" => nil, "error" => "Download request expired or not found. Please try this transfer again.", "http_code" => 404,
              "errors" => nil }
    assert_equal [ 404, error, code, request_id ], [ response.status, response.json.except("data"), *response.json["data"].values_at("file_download_id", "request_id") ]
  end

  # A download URL token of this simulator and reset naming another version: the same fields as the
  # issued token, with its version number replaced.
  def with_version(token, number)
    [ token ].pack("H*").split(":").tap { |fields| fields[-1] = number.to_s }.join(":").unpack1("H*")
  end

  def profile_reset(profile)
    response = control("POST", "reset", { "profile" => profile })
    assert_equal 200, response.status, response.body
  end

  # A simulator whose schema declares the adaptive FileUploadPart fields, as a server generated from
  # the combined adaptive schema does, whichever schema this server was generated from.
  def adaptive_app
    schema_app { |part_fields| part_fields | ADAPTIVE_PART_FIELDS }
  end

  # A simulator whose schema.json has the FileUploadPart fields the block returns, and with
  # `identity`, the download identity parameters the local export b8129459 declares.
  def schema_app(identity: false)
    schema = JSON.parse(File.read(FilesMockServer::Simulation::SCHEMA_PATH))
    schema["entities"]["file_upload_parts"] = yield(schema["entities"]["file_upload_parts"])
    if identity
      schema["operations"]["files.download"]["params"].merge!("with_download_identity" => { "type" => "boolean", "required" => false },
                                                               "expected_download_identity" => { "type" => "string", "required" => false }
      )
    end
    @schema_file = Tempfile.new([ "schema", ".json" ])
    @schema_file.write(JSON.generate(schema))
    @schema_file.close
    Rack::Lint.new(FilesMockServer::Simulation::App.new(limits: FilesMockServer::Simulation::Limits.new, schema_path: @schema_file.path, transfer_origin: ORIGIN))
  end
end
