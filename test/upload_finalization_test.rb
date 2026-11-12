require_relative "test_helper"
require_relative "../with-scenario"

# Finalizes that send async_finalize (Profile::UploadFinalization): completed in their request for
# native storage, and in the background, answered 202 pending until the same request receives the
# retained outcome, for a remote server mount or an Agent.
class UploadFinalizationTest < Minitest::Test
  include SimulationRequests
  include FileRequests

  def setup
    @app = new_app
  end

  def test_native_storage_completes_an_async_finalize_in_its_request_whether_or_not_the_schema_declares_the_flag
    [ app, declared_app ].each do |server|
      @app = server
      first = begin_upload("native.bin")
      etags = [ { "etag" => put_part(first, "abc"), "part" => 1 } ]
      created = api("POST", "/files/native.bin", { "action" => "end", "ref" => first["ref"], "etags" => etags, "async_finalize" => true })
      assert_equal [ 201, "native.bin", 3 ], [ created.status, *created.json.values_at("path", "size") ], created.body
      assert_equal 404, api("POST", "/files/native.bin", { "action" => "end", "ref" => first["ref"], "etags" => etags, "async_finalize" => true }).status
    end
  end

  def test_a_remote_finalize_answers_pending_with_its_progress_then_the_retained_file_to_the_same_request
    profile_reset({ "upload_finalization" => { "destination" => "remote", "pending" => [ 0, nil, 42, 100 ] } })
    first = begin_upload("remote/a.bin", { "mkdir_parents" => true })
    finalize = { "action" => "end", "ref" => first["ref"], "etags" => [ { "etag" => put_part(first, "remote bytes"), "part" => 1 } ], "async_finalize" => "true", "size" => 12 }

    replies = Array.new(4) { api("POST", "/files/remote/a.bin", finalize) }
    assert_equal [ 202 ] * 4, replies.map(&:status)
    expected = [ { "status" => "pending", "ref" => first["ref"], "progress" => 0 }, { "status" => "pending", "ref" => first["ref"] },
                 { "status" => "pending", "ref" => first["ref"], "progress" => 42 }, { "status" => "pending", "ref" => first["ref"], "progress" => 100 } ]
    assert_equal expected, replies.map(&:json)
    # Pending at 100 publishes nothing yet.
    assert_equal 404, api("GET", "/file_actions/metadata/remote/a.bin").status

    created = api("POST", "/files/remote/a.bin", finalize)
    assert_equal [ 201, "remote/a.bin", 12 ], [ created.status, *created.json.values_at("path", "size") ], created.body
    assert_equal "remote bytes", download("remote/a.bin").body
    again = api("POST", "/files/remote/a.bin", finalize)
    assert_equal [ 201, created.json ], [ again.status, again.json ]

    # The upload is gone, so a finalize in its request is 404, and another path never sees the finalization.
    assert_equal 404, api("POST", "/files/remote/a.bin", finalize.except("async_finalize")).status
    assert_equal 404, api("POST", "/files/remote/b.bin", finalize).status
    assert_equal [ [ 202, "pending" ], [ 202, "pending" ], [ 202, "pending" ], [ 202, "pending" ], [ 201, "completed" ], [ 201, "completed" ], [ 404, nil ], [ 404, nil ] ],
                 journaled("files.finalize_upload", %w[status finalization])
  end

  # Under a 4-byte transfer limit, so the failed upload's bytes must stop counting once it is dropped, exactly once: the
  # retained error answers again without releasing them twice, and after a reset a 4-byte upload still fits.
  def test_a_remote_finalize_that_fails_answers_the_same_retained_error_and_leaves_the_ref_unusable
    @app = new_app(max_transfer_bytes: 4)
    failure = { "status" => 422, "type" => "processing-failure/remote-server-error", "message" => "The remote server refused the file" }
    profile_reset({ "upload_finalization" => { "destination" => "remote", "pending" => [ 5 ], "failure" => failure } })
    first = begin_upload("failed.bin")
    finalize = { "action" => "end", "ref" => first["ref"], "etags" => [ { "etag" => put_part(first, "xyz"), "part" => 1 } ], "async_finalize" => true }
    assert_equal 3, bytes_in_use

    assert_equal 202, api("POST", "/files/failed.bin", finalize).status
    failures = Array.new(2) { api("POST", "/files/failed.bin", finalize) }
    answered = failures.map { |reply| [ reply.status, *reply.json.values_at("type", "error") ] }
    assert_equal [ [ 422, "processing-failure/remote-server-error", "The remote server refused the file" ] ] * 2, answered
    assert_equal 404, api("GET", "/file_actions/metadata/failed.bin").status
    assert_equal 404, api("POST", "/files/failed.bin", finalize.except("async_finalize")).status
    assert_equal 0, bytes_in_use

    profile_reset({})
    assert_equal 0, bytes_in_use
    after = begin_upload("after.bin")
    put_part(after, "abcd")
    assert_equal 4, bytes_in_use
  end

  def test_a_remote_finalize_checks_its_parts_when_it_completes_and_keeps_a_failed_check_as_its_outcome
    profile_reset({ "upload_finalization" => { "destination" => "remote" } })
    first = begin_upload("checked.bin")
    put_part(first, "abc")
    wrong = { "action" => "end", "ref" => first["ref"], "etags" => [ { "etag" => put_part(first, "abc"), "part" => 1 } ], "size" => 4, "async_finalize" => true }

    refused = Array.new(2) { api("POST", "/files/checked.bin", wrong) }
    answered = refused.map { |reply| [ reply.status, reply.json["type"] ] }
    assert_equal [ [ 422, "bad-request/request-params-invalid" ] ] * 2, answered
    # The finalization kept the inputs of the request that started it, so a corrected request gets the same answer.
    assert_equal 422, api("POST", "/files/checked.bin", wrong.merge("size" => 3)).status
  end

  def test_a_pending_remote_finalize_reserves_its_path_from_finalizes_in_their_request
    profile_reset({ "upload_finalization" => { "destination" => "remote", "pending" => [ nil ] } })
    first = begin_upload("busy.bin")
    finalize = { "action" => "end", "ref" => first["ref"], "etags" => [ { "etag" => put_part(first, "1"), "part" => 1 } ], "async_finalize" => true }
    assert_equal 202, api("POST", "/files/busy.bin", finalize).status

    other = begin_upload("busy.bin")
    locked = api("POST", "/files/busy.bin", { "action" => "end", "ref" => other["ref"], "etags" => [ { "etag" => put_part(other, "2"), "part" => 1 } ] })
    assert_equal [ 422, "processing-failure/resource-locked" ], [ locked.status, locked.json["type"] ]
    assert_equal 201, api("POST", "/files/busy.bin", finalize).status
  end

  def test_a_profile_and_a_flag_outside_the_contract_are_refused
    refused = control("POST", "reset", { "profile" => { "upload_finalization" => { "pending" => [ 1 ] } } })
    assert_equal [ 400, "profile.upload_finalization.pending and failure apply to destination remote" ], [ refused.status, refused.json["error"] ]
    refused = control("POST", "reset", { "profile" => { "upload_finalization" => { "destination" => "remote", "pending" => [ 101 ] } } })
    assert_equal 400, refused.status
    profile_reset({ "upload_finalization" => { "destination" => "remote" } })
    assert_equal({ "destination" => "remote", "pending" => [] }, control("GET", "ready").json.dig("profile", "upload_finalization"))
    first = begin_upload("flag.bin")
    invalid = api("POST", "/files/flag.bin", { "action" => "end", "ref" => first["ref"], "etags" => [ { "etag" => put_part(first, "z"), "part" => 1 } ], "async_finalize" => "soon" })
    assert_equal [ 422, "async_finalize is invalid" ], [ invalid.status, invalid.json["error"] ]
  end

  # with-scenario.rb's files.finalize_upload background check, over this simulator's own journal: an upload
  # answered pending and then completed with one identity passes; one finalized in its request, or left
  # pending, fails.
  def test_the_background_finalize_check_follows_each_uploads_answers_in_the_journal
    profile_reset({ "upload_finalization" => { "destination" => "remote", "pending" => [ 42 ] } })
    polled = begin_upload("polled.bin")
    finalize = { "action" => "end", "ref" => polled["ref"], "etags" => [ { "etag" => put_part(polled, "p"), "part" => 1 } ], "async_finalize" => true }
    2.times { api("POST", "/files/polled.bin", finalize) }
    check = ScenarioRun.allocate
    assert_equal [], check.send(:background_finalize_problems, journal)

    direct = begin_upload("direct.bin")
    api("POST", "/files/direct.bin", { "action" => "end", "ref" => direct["ref"], "etags" => [ { "etag" => put_part(direct, "d"), "part" => 1 } ] })
    abandoned = begin_upload("abandoned.bin")
    api("POST", "/files/abandoned.bin", { "action" => "end", "ref" => abandoned["ref"], "etags" => [ { "etag" => put_part(abandoned, "a"), "part" => 1 } ], "async_finalize" => true })
    problems = check.send(:background_finalize_problems, journal)
    assert_equal 3, problems.size, problems.inspect
    assert(problems.any? { |problem| problem.include?("was never answered pending") })
    assert(problems.any? { |problem| problem.include?("was not completed after 1 pending answers") })
  end

  private

  def bytes_in_use
    control("GET", "ready").json.dig("transfers", "state", "bytes_in_use")
  end

  def profile_reset(profile)
    response = control("POST", "reset", { "profile" => profile })
    assert_equal 200, response.status, response.body
  end

  # A simulator whose schema declares async_finalize for files.finalize_upload, as one generated from
  # a files-rails schema with background finalization does, whichever schema this server was generated from.
  def declared_app
    schema = JSON.parse(File.read(FilesMockServer::Simulation::SCHEMA_PATH))
    schema["operations"]["files.finalize_upload"]["params"]["async_finalize"] = { "type" => "boolean", "required" => false }
    @schema_file = Tempfile.new([ "schema", ".json" ])
    @schema_file.write(JSON.generate(schema))
    @schema_file.close
    Rack::Lint.new(FilesMockServer::Simulation::App.new(limits: FilesMockServer::Simulation::Limits.new, schema_path: @schema_file.path, transfer_origin: ORIGIN))
  end
end
