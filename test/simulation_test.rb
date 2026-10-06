require_relative "test_helper"

class SimulationTest < Minitest::Test
  include SimulationRequests

  FIVE_USERS = (1..5).map { |number| { "username" => "user#{number}" } }.freeze

  # Built up front: a lazily memoized simulator could be created twice by concurrent test threads.
  def setup
    @app = new_app
  end

  def test_user_lifecycle_keeps_identity_and_never_reuses_ids
    created = api("POST", "/users", { "username" => "alice", "email" => "alice@example.com", "password" => "never-returned-secret" })
    assert_equal 201, created.status
    assert_equal({ "id" => 1, "username" => "alice", "email" => "alice@example.com" }, created.json)
    assert_equal 2, api("POST", "/users", { "username" => "bob" }).json["id"]

    updated = api("PATCH", "/users/1", { "name" => "Alice Example" })
    assert_equal 200, updated.status
    assert_equal({ "id" => 1, "username" => "alice", "email" => "alice@example.com", "name" => "Alice Example" }, updated.json)
    assert_equal updated.json, api("GET", "/users/1").json

    deleted = api("DELETE", "/users/1")
    assert_equal [ 204, "" ], [ deleted.status, deleted.body ]
    missing = api("GET", "/users/1")
    assert_equal 404, missing.status
    assert_equal({ "error" => "Not Found.  This may be related to your permissions.", "http-code" => 404, "title" => "Not Found", "type" => "not-found" }, missing.json)
    assert_equal [ 404, 404, 404 ], [ api("PATCH", "/users/1", { "name" => "x" }), api("DELETE", "/users/1"), api("GET", "/users/abc") ].map(&:status)

    assert_equal 3, api("POST", "/users", { "username" => "carol" }).json["id"]
    assert_equal %w[bob carol], usernames
    journal = control("GET", "journal")
    refute_includes journal.body, "never-returned-secret"
    # A create's journal entry names the ID it allocated; other entries name the ID from the path.
    journaled = journal.json["entries"].values_at(0, 2).map { |entry| entry.values_at("operation", "id", "status") }
    assert_equal [ [ "users.create", 1, 201 ], [ "users.update", 1, 200 ] ], journaled
  end

  # The journal shows each request's paging as it was sent and each response's cursor headers, by
  # JSON type and SHA-256 and never by value, beside the entry's other fields: each cursor a request
  # sent is the next cursor of the page before, and the last page names none.
  def test_five_users_page_by_two_across_three_pages_exactly_once
    reset({ "users" => FIVE_USERS })
    identity = { "HTTP_X_FILESAPI_KEY" => "synthetic-key-sentinel", "HTTP_USER_AGENT" => "paging journal probe" }
    pages = []
    issued = []
    cursor = nil
    loop do
      query = Rack::Utils.build_nested_query({ "per_page" => 2, "cursor" => cursor }.compact)
      response = request(app, "GET", "/api/rest/v1/users?#{query}", nil, identity)
      assert_equal 200, response.status
      pages << response.json.map { |user| user["username"] }
      cursor = response.headers["x-files-cursor"]
      unless cursor
        refute response.headers.key?("x-files-cursor-next"), "the last page must not name a next page"
        break
      end
      assert_equal cursor, response.headers["x-files-cursor-next"]
      issued << cursor
      flunk "pagination did not end: #{pages.inspect}" if pages.size > 3
    end
    assert_equal [ %w[user1 user2], %w[user3 user4], %w[user5] ], pages

    journal = control("GET", "journal")
    entries = journal.json["entries"]
    assert_equal [ true, 0, %w[users.list] * 3 ], [ journal.json["complete"], journal.json["dropped"], entries.map { |entry| entry["operation"] } ]
    assert_equal([ [ 200, nil, { "api_key" => 1 }, "paging journal probe" ] ] * 3, entries.map { |entry| entry.values_at("status", "fault_id", "credentials", "user_agent") })
    per_page = { "present" => true, "wire_type" => "string", "sha256" => Digest::SHA256.hexdigest("2"), "integer" => 2 }
    assert_equal([ [ true, per_page, true, "selected-rack-response-before-delivery" ] ] * 3,
                 entries.map { |entry| entry["paging"]["request"].values_at("available", "per_page") + entry["paging"]["response"].values_at("available", "basis") }
                )
    absent = { "present" => false, "wire_type" => nil, "sha256" => nil, "nonempty" => false }
    cursors = issued.map { |value| { "present" => true, "wire_type" => "string", "sha256" => Digest::SHA256.hexdigest(value), "nonempty" => true } }
    assert_equal([ absent, *cursors ], entries.map { |entry| entry["paging"]["request"]["cursor"] })
    assert_equal([ *cursors, absent ].map { |headers| [ headers, headers ] }, entries.map { |entry| entry["paging"]["response"].values_at("cursor", "cursor_next") })
    [ "synthetic-key-sentinel", *issued ].each { |value| refute_includes journal.body, value }
  end

  # Paging values a request left out, sent as another JSON type or empty, or sent in a body that
  # could not be read, are journaled as exactly that, whatever the list then answered: never as the
  # per_page or cursor it assumed. Only a page that continues has cursor headers.
  def test_the_journal_types_missing_malformed_and_unreadable_paging_values
    reset({ "users" => FIVE_USERS })
    statuses = [
      api("GET", "/users"),
      api("GET", "/users", { "per_page" => "two" }),
      request(app, "GET", "/api/rest/v1/users", JSON.generate("per_page" => 2)),
      api("GET", "/users", { "per_page" => 2, "cursor" => "" }),
      api("GET", "/users", { "cursor" => [ "a" ] }),
      request(app, "GET", "/api/rest/v1/users", "{not json")
    ].map(&:status)
    assert_equal [ 200, 422, 200, 200, 422, 422 ], statuses

    missing = { "present" => false, "wire_type" => nil, "sha256" => nil }
    no_per_page = missing.merge("integer" => nil)
    no_cursor = missing.merge("nonempty" => false)
    two = { "present" => true, "wire_type" => "string", "sha256" => Digest::SHA256.hexdigest("2"), "integer" => 2 }
    expected = [
      [ true, no_per_page, no_cursor ],
      [ true, { "present" => true, "wire_type" => "string", "sha256" => Digest::SHA256.hexdigest("two"), "integer" => nil }, no_cursor ],
      [ true, { "present" => true, "wire_type" => "number", "sha256" => nil, "integer" => 2 }, no_cursor ],
      [ true, two, { "present" => true, "wire_type" => "string", "sha256" => Digest::SHA256.hexdigest(""), "nonempty" => false } ],
      [ true, no_per_page, { "present" => true, "wire_type" => "array", "sha256" => nil, "nonempty" => false } ],
      [ false, no_per_page, no_cursor ]
    ]
    entries = control("GET", "journal").json["entries"]
    assert_equal(expected, entries.map { |entry| entry["paging"]["request"].values_at("available", "per_page", "cursor") })
    continues = [ false, false, true, true, false, false ].map { |present| [ true, present, present ] }
    assert_equal(continues, entries.map { |entry| entry["paging"]["response"].then { |response| [ response["available"], response["cursor"]["present"], response["cursor_next"]["present"] ] } })
  end

  # The journal's paging response is the one this step selected after any fault rule: an empty
  # page's cursor headers, which later requests send back as they got them (not as the simulator
  # resolves them), an injected error's lack of any, and none at all for a connection dropped before
  # the request was applied, which is no last page.
  def test_the_journal_paging_response_is_the_one_a_fault_rule_selected
    reset({ "users" => FIVE_USERS })
    first = api("GET", "/users", { "per_page" => 2 })
    add_fault({ "operation" => "users.list", "match" => { "continuation" => true }, "kind" => "empty_page" })
    empty = api("GET", "/users", { "per_page" => 2, "cursor" => first.headers["x-files-cursor"] })
    add_fault({ "operation" => "users.list", "match" => { "continuation" => true }, "status" => 503 })
    failed = api("GET", "/users", { "per_page" => 2, "cursor" => empty.headers["x-files-cursor"] })
    second = api("GET", "/users", { "per_page" => 2, "cursor" => empty.headers["x-files-cursor"] })
    assert_equal [ [], 503, %w[user3 user4] ], [ empty.json, failed.status, second.json.map { |user| user["username"] } ]
    add_fault({ "operation" => "users.list", "kind" => "drop_before" })
    connection, client = Socket.pair(:UNIX, :STREAM)
    query = Rack::Utils.build_nested_query({ "per_page" => 2, "cursor" => second.headers["x-files-cursor"] })
    raw_request(app, "GET", "/api/rest/v1/users?#{query}", nil, { "rack.hijack?" => true, "rack.hijack" => -> { connection } })

    absent = { "present" => false, "wire_type" => nil, "sha256" => nil, "nonempty" => false }
    issued = [ first, empty, second ].map { |response| { "present" => true, "wire_type" => "string", "sha256" => Digest::SHA256.hexdigest(response.headers.fetch("x-files-cursor")), "nonempty" => true } }
    entries = control("GET", "journal").json["entries"]
    assert_equal([ absent, issued[0], issued[1], issued[1], issued[2] ], entries.map { |entry| entry["paging"]["request"]["cursor"] })
    assert_equal([ [ 200, true, issued[0] ], [ 200, true, issued[1] ], [ 503, true, absent ], [ 200, true, issued[2] ], [ nil, false, absent ] ],
                 entries.map { |entry| [ entry["status"], *entry["paging"]["response"].values_at("available", "cursor") ] }
                )
    assert_equal(entries.map { |entry| entry["paging"]["response"]["cursor"] }, entries.map { |entry| entry["paging"]["response"]["cursor_next"] })
    assert_equal [ "empty_page", issued[0]["sha256"], issued[1]["sha256"] ], entries[1].values_at("fault_kind", "cursor_sha256", "next_cursor_sha256")
    assert_equal "drop_before", entries[4]["fault_kind"]
  ensure
    [ connection, client ].each { |socket| socket&.close }
  end

  def test_users_created_or_deleted_during_a_traversal_are_neither_repeated_nor_lost
    reset({ "users" => FIVE_USERS })
    first = api("GET", "/users", { "per_page" => 2 })
    api("DELETE", "/users/3")
    api("POST", "/users", { "username" => "user6" })
    second = api("GET", "/users", { "per_page" => 2, "cursor" => first.headers["x-files-cursor"] })
    third = api("GET", "/users", { "per_page" => 2, "cursor" => second.headers["x-files-cursor"] })
    pages = [ first, second, third ].map { |page| page.json.map { |user| user["username"] } }
    assert_equal [ %w[user1 user2], %w[user4 user5], %w[user6] ], pages
    assert_nil third.headers["x-files-cursor"]
  end

  def test_malformed_stale_and_cross_scope_cursors_are_rejected
    reset({ "users" => FIVE_USERS })
    cursor = api("GET", "/users", { "per_page" => 2 }).headers["x-files-cursor"]
    other_simulator = new_app
    reset({ "users" => FIVE_USERS }, to: other_simulator)
    rejected = {
      "malformed" => api("GET", "/users", { "per_page" => 2, "cursor" => "not-a-cursor" }),
      "different page size" => api("GET", "/users", { "per_page" => 3, "cursor" => cursor }),
      "different simulator" => api("GET", "/users", { "per_page" => 2, "cursor" => cursor }, to: other_simulator),
    }
    reset({ "users" => FIVE_USERS })
    rejected["before reset"] = api("GET", "/users", { "per_page" => 2, "cursor" => cursor })

    rejected.each do |name, response|
      assert_equal [ 422, "bad-request/invalid-cursor" ], [ response.status, response.json["type"] ], name
    end
  end

  def test_per_page_must_be_a_positive_bounded_whole_number
    { 0 => "bad-request/request-params-invalid", 10_001 => "bad-request/request-params-invalid", "two" => "bad-request" }.each do |per_page, type|
      response = api("GET", "/users", { "per_page" => per_page })
      assert_equal [ 422, type ], [ response.status, response.json["type"] ], per_page.inspect
    end
    assert_equal 200, api("GET", "/users", { "per_page" => 10_000 }).status
  end

  def test_invalid_enum_and_date_time_values_are_rejected_before_any_change
    invalid = api("POST", "/users", { "username" => "alice", "ssl_required" => "sometimes", "authenticate_until" => "next tuesday" })
    assert_equal [ 422, "bad-request" ], [ invalid.status, invalid.json["type"] ]
    assert_includes invalid.json["error"], "ssl_required does not have a valid value"
    assert_includes invalid.json["error"], "authenticate_until is invalid"
    assert_equal "username is missing", api("POST", "/users", { "ssl_required" => "always_require" }).json["error"]
    # Impossible moments, and a time without a UTC offset, which only a file's provided_mtime accepts.
    [ "2026-02-30T12:00:00Z", "2030-01-01T24:00:00Z", "2030-01-02T03:04:05" ].each do |rejected|
      response = api("POST", "/users", { "username" => "alice", "authenticate_until" => rejected })
      assert_equal [ 422, "authenticate_until is invalid" ], [ response.status, response.json["error"] ], rejected
    end
    assert_empty usernames

    valid_params = { "username" => "alice", "ssl_required" => "always_require", "authenticate_until" => "2030-01-02T03:04:05+02:00", "require_login_by" => "2028-02-29T23:30:00-05:00" }
    valid = api("POST", "/users", valid_params)
    assert_equal 201, valid.status
    assert_equal [ 1, "always_require", "2030-01-02T01:04:05Z", "2028-03-01T04:30:00Z" ], valid.json.values_at("id", "ssl_required", "authenticate_until", "require_login_by")

    rejected_update = api("PATCH", "/users/1", { "name" => "changed", "require_2fa" => "sometimes" })
    assert_equal 422, rejected_update.status
    assert_equal valid.json, api("GET", "/users/1").json
  end

  def test_unmodeled_operations_and_parameters_fail_visibly_without_changes
    reset({ "users" => [ { "username" => "alice" } ] })
    responses = {
      "another resource's action" => api("POST", "/automations/1/manual_run"),
      "user action" => api("POST", "/users/1/unlock"),
      "PUT update" => api("PUT", "/users/1", { "name" => "changed" }),
      "sorting" => api("GET", "/users", { "sort_by" => { "username" => "desc" } }),
      "search" => api("GET", "/users", { "search" => "ali" }),
      "group membership" => api("POST", "/users", { "username" => "bob", "group_id" => 1 }),
      "avatar" => api("PATCH", "/users/1", { "avatar_delete" => true }),
      "ownership transfer" => api("DELETE", "/users/1", { "new_owner_id" => 2 }),
      "text body" => request(app, "POST", "/api/rest/v1/users", "username=bob", "CONTENT_TYPE" => "text/plain"),
    }
    responses.each do |name, response|
      assert_equal [ 501, "simulation/not-supported" ], [ response.status, response.json["type"] ], name
    end
    assert_equal({ "id" => 1, "username" => "alice" }, api("GET", "/users/1").json)
    assert_equal %w[alice], usernames
  end

  def test_head_requests_keep_their_error_status_with_an_empty_body
    { "/api/rest/v1/users" => 501, "/__files_mock/v1/ready" => 404, "/" => 404 }.each do |path, status|
      response = request(app, "HEAD", path)
      assert_equal [ status, "" ], [ response.status, response.body ], path
    end
  end

  def test_first_attempt_fault_fails_once_before_any_change
    reset({ "users" => [ { "username" => "alice" } ] })
    rule = add_fault({ "operation" => "users.update", "match" => { "id" => 1 }, "status" => 503, "retry_after" => 2 })
    assert_equal "pending", rule["state"]

    faulted = api("PATCH", "/users/1", { "name" => "first attempt" })
    assert_equal [ 503, "2", "simulation/injected-fault" ], [ faulted.status, faulted.headers["retry-after"], faulted.json["type"] ]
    assert_nil api("GET", "/users/1").json["name"]
    assert_equal 200, api("PATCH", "/users/1", { "name" => "retry" }).status
    assert_equal "retry", api("GET", "/users/1").json["name"]

    faults = control("GET", "faults").json
    assert_equal [ 0, 1 ], faults.values_at("pending", "consumed")
    consumed_by = faults["faults"].first["consumed_by_request"]
    entry = control("GET", "journal").json["entries"].detect { |candidate| candidate["seq"] == consumed_by }
    assert_equal [ "users.update", 1, 503, rule["id"] ], entry.values_at("operation", "id", "status", "fault_id")
  end

  def test_faulted_create_allocates_no_id_so_a_retry_creates_one_user
    add_fault({ "operation" => "users.create", "match" => { "username" => "alice" }, "status" => 503 })
    assert_equal 201, api("POST", "/users", { "username" => "bob" }).status
    assert_equal 503, api("POST", "/users", { "username" => "alice" }).status
    assert_equal 2, api("POST", "/users", { "username" => "alice" }).json["id"]
    assert_equal %w[bob alice], usernames
  end

  def test_fault_is_consumed_exactly_once_and_never_by_unrelated_concurrent_requests
    reset({ "users" => [ { "username" => "alice" }, { "username" => "bob" } ] })
    rule = add_fault({ "operation" => "users.update", "match" => { "id" => 2 }, "status" => 503 })
    start = Queue.new
    unrelated = Array.new(30) do |number|
      Thread.new do
        start.pop
        case number % 3
        when 0 then api("PATCH", "/users/1", { "name" => "alice #{number}" })
        when 1 then api("GET", "/users/2")
        else api("GET", "/users")
        end
      end
    end
    matching = Array.new(5) do |number|
      Thread.new do
        start.pop
        [ "bob #{number}", api("PATCH", "/users/2", { "name" => "bob #{number}" }) ]
      end
    end
    (unrelated.size + matching.size).times { start << true }

    assert_equal [ 200 ], unrelated.map { |thread| thread.value.status }.uniq
    faulted, succeeded = matching.map(&:value).partition { |_name, response| response.status == 503 }
    assert_equal 1, faulted.size
    assert_equal [ 200 ], succeeded.map { |_name, response| response.status }.uniq
    final_name = api("GET", "/users/2").json["name"]
    assert_includes succeeded.map(&:first), final_name

    consumed = control("GET", "faults").json["faults"].first
    assert_equal [ "consumed", 1 ], consumed.values_at("state", "matched_requests")
    entry = control("GET", "journal").json["entries"].detect { |candidate| candidate["fault_id"] == rule["id"] }
    assert_equal [ consumed["consumed_by_request"], "users.update", 2, 503 ], entry.values_at("seq", "operation", "id", "status")
  end

  def test_unused_fault_stays_pending_and_visible
    add_fault({ "operation" => "users.list", "status" => 500 })
    api("POST", "/users", { "username" => "alice" })
    fault = control("GET", "faults").json["faults"].first
    assert_equal [ "pending", 0, nil ], fault.values_at("state", "matched_requests", "consumed_by_request")
    assert_equal 1, control("GET", "ready").json["state"]["pending_faults"]
  end

  def test_fault_rules_are_validated_and_cannot_overlap
    [
      { "operation" => "users.unlock", "status" => 503 },
      { "operation" => "users.update", "status" => 418 },
      { "operation" => "users.update", "status" => 503.0 },
      { "operation" => "users.update", "status" => 503, "attempt" => 0 },
      { "operation" => "users.update", "status" => 503, "retry_after" => 3600 },
      { "operation" => "users.update", "status" => 503, "match" => { "username" => "alice" } },
      { "operation" => "users.list", "status" => 503, "match" => { "id" => 1 } },
      { "operation" => "users.update", "status" => 503, "delay_seconds" => 5 }
    ].each do |rule|
      response = control("POST", "faults", rule)
      assert_equal [ 400, "simulation/invalid-control-request" ], [ response.status, response.json["type"] ], rule.inspect
    end

    add_fault({ "operation" => "users.update", "match" => { "id" => 1 }, "status" => 503 })
    assert_equal 409, control("POST", "faults", { "operation" => "users.update", "status" => 500 }).status
    assert_equal 201, control("POST", "faults", { "operation" => "users.update", "match" => { "id" => 2 }, "status" => 500 }).status
    assert_equal 415, request(app, "POST", "/__files_mock/v1/faults", "{}", "CONTENT_TYPE" => "text/plain").status
  end

  def test_reset_replays_fixtures_and_clears_records_counters_journal_and_faults
    first = reset({ "users" => FIVE_USERS })
    listing = api("GET", "/users").json
    api("DELETE", "/users/1")
    api("POST", "/users", { "username" => "extra" })
    add_fault({ "operation" => "users.list", "status" => 503 })

    second = reset({ "users" => FIVE_USERS })
    assert_equal [ [ 1, 2, 3, 4, 5 ], first["epoch"] + 1 ], [ second["users"], second["epoch"] ]
    assert_equal listing, api("GET", "/users").json
    assert_equal 6, api("POST", "/users", { "username" => "next" }).json["id"]
    assert_equal [ [], 0 ], control("GET", "faults").json.values_at("faults", "pending")
    journal = control("GET", "journal").json
    assert_equal [ [ 1, 2 ], true ], [ journal["entries"].map { |entry| entry["seq"] }, journal["complete"] ]
  end

  def test_write_in_flight_during_reset_is_refused
    input = InterruptedBody.new(JSON.generate("username" => "late"), -> { reset({ "users" => [ { "username" => "fixture" } ] }) })
    env = Rack::MockRequest.env_for("/api/rest/v1/users", method: "POST", input:, "CONTENT_TYPE" => "application/json")
    status, _headers, body = app.call(env)
    payload = +""
    body.each { |part| payload << part }
    body.close
    assert_equal [ 409, "simulation/stale-request" ], [ status, JSON.parse(payload)["type"] ]

    assert_equal %w[fixture], usernames
    entry = control("GET", "journal").json["entries"].first
    assert_equal [ "users.create", 409 ], entry.values_at("operation", "status")
  end

  def test_record_limit_rejects_writes_and_resets_without_partial_changes
    simulator = new_app(max_records: 2)
    reset({ "users" => [ { "username" => "a" }, { "username" => "b" } ] }, to: simulator)
    full = api("POST", "/users", { "username" => "c" }, to: simulator)
    assert_equal [ 409, "simulation/limit-exceeded" ], [ full.status, full.json["type"] ]

    oversized_reset = control("POST", "reset", { "fixtures" => { "users" => [ { "username" => "x" }, { "username" => "y" }, { "username" => "z" } ] } }, to: simulator)
    assert_equal 409, oversized_reset.status
    assert_includes oversized_reset.json["error"], "fixtures.users[2]"
    assert_equal [ 1, %w[a b] ], [ control("GET", "ready", to: simulator).json["epoch"], usernames(to: simulator) ]

    api("DELETE", "/users/1", to: simulator)
    assert_equal 3, api("POST", "/users", { "username" => "c" }, to: simulator).json["id"]
  end

  def test_oversized_body_is_rejected_without_a_write
    simulator = new_app(max_body_bytes: 64)
    response = api("POST", "/users", { "username" => "x" * 100 }, to: simulator)
    assert_equal [ 413, "simulation/limit-exceeded" ], [ response.status, response.json["type"] ]
    assert_empty usernames(to: simulator)
  end

  def test_journal_reports_overflow_instead_of_truncating_silently
    simulator = new_app(max_journal_entries: 3)
    4.times { api("GET", "/users", to: simulator) }
    journal = control("GET", "journal", to: simulator).json
    assert_equal [ [ 1, 2, 3 ], 1, false ], [ journal["entries"].map { |entry| entry["seq"] }, journal["dropped"], journal["complete"] ]
    refute control("GET", "ready", to: simulator).json["state"]["journal_complete"]
  end

  def test_simulators_do_not_share_records_faults_or_resets
    first = new_app
    second = new_app
    [ first, second ].each { |simulator| reset({ "users" => [ { "username" => "shared" } ] }, to: simulator) }
    api("POST", "/users", { "username" => "only-first" }, to: first)
    add_fault({ "operation" => "users.list", "status" => 503 }, to: first)

    assert_equal %w[shared], usernames(to: second)
    reset({}, to: second)
    assert_equal 503, api("GET", "/users", to: first).status
    assert_equal %w[shared only-first], usernames(to: first)
  end

  def test_concurrent_creates_get_unique_consecutive_ids
    threads = Array.new(40) { |number| Thread.new { api("POST", "/users", { "username" => "user#{number}" }).json["id"] } }
    assert_equal (1..40).to_a, threads.map(&:value).sort
    assert_equal 40, usernames.size
  end

  def test_readiness_identifies_the_simulator_and_its_operations
    ready = control("GET", "ready").json
    assert_equal [ "ready", "simulation", 3 ], ready.values_at("status", "mode", "contract_version")
    assert_match(/\A\h{64}\z/, ready["schema_sha256"])
    refute_empty ready["simulator_version"]
    operations = ready["operations"].to_h { |operation| [ operation["id"], operation["swagger_operation_id"] ] }
    assert_equal %w[users.create users.list users.find users.update users.delete], operations.keys.first(5)
    files = { "files.begin_upload" => "FileActionBeginUpload", "files.finalize_upload" => "PostFilesPath", "files.download" => "FileDownload", "files.metadata" => "FileActionFind",
              "files.delete" => "DeleteFilesPath", "folders.create" => "PostFoldersPath", "folders.list" => "FolderListForPath" }
    assert_equal files, operations.drop(5).first(7).to_h
    # Record resources follow, each with the Swagger operation it answers.
    assert_equal({ "groups.list" => "GetGroups", "groups.create" => "PostGroups" }, operations.slice("groups.list", "groups.create"))
    assert_equal(%w[transfers.upload_part transfers.download], ready["transfers"]["operations"].map { |operation| operation["id"] })
    assert_equal({ "http_method" => "PUT", "parallel_parts" => false, "retry_parts" => true, "partsize" => 1_048_576 }, ready["transfers"]["upload_parts"])
    assert_equal [ 33_554_432, { "uploads" => 0, "files" => 0, "bytes_in_use" => 0 } ], [ ready["limits"]["max_transfer_bytes"], ready["transfers"]["state"] ]
    # What the simulator declares instead of answering like a particular real site.
    assert_equal %w[listed omitted], ready["transfers"]["finalize_etags"]
    assert_equal [ { "always_mkdir_parents" => true }, { "recursive" => true, "root" => false }, { "files" => 0, "folders" => 0, "cursors" => 0 } ], ready["namespace"].values_at("site_policy", "delete", "state")
    assert_includes ready["real_only"], "authentication"
  end

  def test_simulation_refuses_to_start_without_the_simulated_operations_in_its_schema
    schema = JSON.parse(File.read(FilesMockServer::Simulation::SCHEMA_PATH))
    schema["operations"].delete("users.delete")
    schema["entities"].delete("users")
    Tempfile.create([ "schema", ".json" ]) do |file|
      file.write(JSON.generate(schema))
      file.close
      error = assert_raises(ArgumentError) { FilesMockServer::Simulation::App.new(schema_path: file.path) }
      assert_includes error.message, "DELETE /api/rest/v1/users/{id}"
      assert_includes error.message, "the User entity"
    end
  end

  def test_limit_settings_must_be_bounded_whole_numbers
    assert_equal 5, FilesMockServer::Simulation::Limits.from_env("FILES_MOCK_MAX_RECORDS" => "5").max_records
    [ "0", "-1", "ten", "100001" ].each do |value|
      assert_raises(ArgumentError, value) { FilesMockServer::Simulation::Limits.from_env("FILES_MOCK_MAX_RECORDS" => value) }
    end
  end
end
