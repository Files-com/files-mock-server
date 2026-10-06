require_relative "test_helper"

# Fault rules beyond a first-attempt error: Files.com error types, answers from a web tier or
# storage provider, paging continuation faults, delays, and seeded random rules. Faults that close
# or cut the connection need a real server (see ConnectionFaultsTest).
class FaultsTest < Minitest::Test
  include SimulationRequests
  include FileRequests

  def setup
    @app = new_app
  end

  def test_an_error_fault_can_name_a_files_error_type_and_shows_it_was_injected
    reset({ "groups" => [ { "name" => "a" } ] })
    rule = add_fault({ "operation" => "groups.find", "match" => { "id" => 1 }, "status" => 404, "type" => "not-found", "message" => "Not Found" })
    faulted = api("GET", "/groups/1")
    assert_equal [ 404, { "error" => "Not Found", "http-code" => 404, "title" => "Not Found", "type" => "not-found" }, rule["id"].to_s ],
                 [ faulted.status, faulted.json, faulted.headers["x-files-mock-fault"] ]
    assert_equal 200, api("GET", "/groups/1").status
  end

  # A lockout region mismatch names the host the site must use in "data". A rule can answer with it,
  # so a client's reroute can be checked against a local answer; real relocation is a real-lane check.
  def test_an_error_fault_can_carry_error_data_such_as_a_lockout_region_host
    add_fault({ "operation" => "users.list", "status" => 401, "type" => "not-authenticated/lockout-region-mismatch", "message" => "Your account must login using a different server.",
                "data" => { "host" => "127.0.0.1:4043" } }
    )
    mismatch = api("GET", "/users")
    assert_equal [ 401, "Lockout Region Mismatch", { "host" => "127.0.0.1:4043" } ], [ mismatch.status, *mismatch.json.values_at("title", "data") ]
    refute api("GET", "/users").json.is_a?(Hash), "the next request is not faulted"
    [ { "status" => 401, "data" => "host" }, { "status" => 401, "data" => { "host" => "x" * 4097 } }, { "kind" => "unstructured", "status" => 502, "data" => {} } ].each do |bad|
      assert_equal 400, control("POST", "faults", { "operation" => "users.list" }.merge(bad)).status, bad.inspect[0, 80]
    end
  end

  def test_web_tier_and_storage_answers_are_not_files_json
    reset({ "files" => [ { "path" => "f.bin", "text" => "bytes" } ] })
    add_fault({ "operation" => "users.list", "kind" => "unstructured", "status" => 502, "retry_after" => 3 })
    gateway = api("GET", "/users")
    assert_equal [ 502, "text/html", "3" ], [ gateway.status, gateway.headers["content-type"], gateway.headers["retry-after"] ]
    assert_includes gateway.body, "<h1>502 Bad Gateway</h1>"

    add_fault({ "operation" => "transfers.download", "kind" => "html_page" })
    page = download("f.bin")
    assert_equal [ 200, "text/html; charset=utf-8", "true" ], [ page.status, page.headers["content-type"], page.headers["x-files-frontend-app"] ]
    assert_equal FilesMockServer::Simulation::Delivery::HTML_PAGE, page.body
    assert_equal "bytes", download("f.bin").body

    part = begin_upload("g.bin")
    add_fault({ "operation" => "transfers.upload_part", "kind" => "expired_url" })
    expired = transfer("PUT", part["upload_uri"], "new")
    assert_equal [ 403, "application/xml" ], [ expired.status, expired.headers["content-type"] ]
    assert_includes expired.body, "<Message>Request has expired</Message>"
    etag = put_part(part, "new")
    assert_equal 201, api("POST", "/files/g.bin", { "action" => "end", "ref" => part["ref"], "etags" => [ { "etag" => etag, "part" => 1 } ] }).status
    assert_equal [ [ 403, "expired_url" ], [ 200, nil ] ], journaled("transfers.upload_part", %w[status fault_kind])
  end

  # Numbered identities are bounded: a new one past the limit is refused before its request changes anything.
  def test_a_new_identity_past_the_limit_is_refused_before_any_change
    limit = FilesMockServer::Simulation::State::MAX_CREDENTIALS
    limit.times { |number| request(app, "GET", "/api/rest/v1/groups", nil, { "HTTP_X_FILESAPI_KEY" => "sentinel-#{number}" }) }
    refused = request(app, "POST", "/api/rest/v1/groups", JSON.generate("name" => "late"), { "HTTP_X_FILESAPI_KEY" => "sentinel-new" })
    assert_equal [ 409, "simulation/limit-exceeded" ], [ refused.status, refused.json["type"] ]
    assert_equal [], api("GET", "/groups").json
    assert_equal({ "api_key" => "unnumbered" }, journal.find { |entry| entry["status"] == 409 }["credentials"])
    known = request(app, "POST", "/api/rest/v1/groups", JSON.generate("name" => "known"), { "HTTP_X_FILESAPI_KEY" => "sentinel-7" })
    assert_equal [ 201, 1 ], [ known.status, known.json["id"] ]
    reset
    assert_equal 201, request(app, "POST", "/api/rest/v1/groups", JSON.generate("name" => "after reset"), { "HTTP_X_FILESAPI_KEY" => "sentinel-new" }).status

    # A refused part send counts nothing for the part: a known identity then makes its first send,
    # even where retries are forbidden.
    assert_equal 200, control("POST", "reset", { "profile" => { "upload" => { "mode" => "serial", "partsize" => 4, "retry_parts" => false } } }).status
    part = begin_upload("capped.bin", { "size" => 4 })
    limit.times { |number| request(app, "GET", "/api/rest/v1/site", nil, { "HTTP_X_FILESAPI_KEY" => "sentinel-#{number}" }) }
    refused = transfer("PUT", part["upload_uri"], "abcd", { "HTTP_X_FILESAPI_KEY" => "sentinel-new" })
    assert_equal [ 409, "simulation/limit-exceeded" ], [ refused.status, refused.json["type"] ]
    accepted = transfer("PUT", part["upload_uri"], "abcd", { "HTTP_X_FILESAPI_KEY" => "sentinel-0" })
    assert_equal [ 200, 4 ], [ accepted.status, control("GET", "ready").json.dig("transfers", "state", "bytes_in_use") ]
  end

  # The journal names each API key and session by the order it first appeared, never by its value,
  # so a scenario can see which credential reached which origin.
  def test_redirects_send_the_client_to_another_origin_whose_journal_shows_which_identity_arrived
    other = new_app
    add_fault({ "operation" => "users.list", "kind" => "redirect", "location" => "http://127.0.0.1:4099" })
    redirected = api("GET", "/users", { "per_page" => 1 })
    assert_equal [ 307, "http://127.0.0.1:4099/api/rest/v1/users?per_page=1", "" ], [ redirected.status, redirected.headers["location"], redirected.body ]
    identity = { "HTTP_X_FILESAPI_KEY" => "key-a-sentinel", "HTTP_X_FILES_WORKSPACE_ID" => "123" }
    request(other, "GET", "/api/rest/v1/users?per_page=1", nil, identity)
    request(other, "GET", "/api/rest/v1/users?per_page=1", nil, { "HTTP_X_FILESAPI_AUTH" => "session-b-sentinel" })
    request(other, "GET", "/api/rest/v1/users?per_page=1", nil, identity)
    request(other, "GET", "/api/rest/v1/users?per_page=1", nil, { "HTTP_USER_AGENT" => "Files.com JavaScript SDK v2.0.0" })
    journal = control("GET", "journal", to: other)
    assert_equal([ { "api_key" => 1, "workspace_id" => "123" }, { "session" => 2 }, { "api_key" => 1, "workspace_id" => "123" }, nil ],
                 journal.json["entries"].map { |entry| entry["credentials"] }
                )
    assert_equal "Files.com JavaScript SDK v2.0.0", journal.json["entries"].last["user_agent"]
    %w[key-a-sentinel session-b-sentinel].each { |credential| refute_includes journal.body, credential }
  end

  def test_paging_faults_can_fail_only_continuation_requests
    reset({ "groups" => (1..3).map { |number| { "name" => "g#{number}" } } })
    add_fault({ "operation" => "groups.list", "match" => { "continuation" => true }, "status" => 503, "retry_after" => 1 })
    first = api("GET", "/groups", { "per_page" => 1 })
    assert_equal [ 200, [ "g1" ] ], [ first.status, first.json.map { |group| group["name"] } ]
    cursor = first.headers["x-files-cursor"]
    assert_equal 503, api("GET", "/groups", { "per_page" => 1, "cursor" => cursor }).status
    retried = api("GET", "/groups", { "per_page" => 1, "cursor" => cursor })
    assert_equal [ 200, [ "g2" ] ], [ retried.status, retried.json.map { |group| group["name"] } ]

    upload("dir/a", [ "a" ])
    upload("dir/b", [ "b" ])
    add_fault({ "operation" => "folders.list", "match" => { "path" => "dir", "continuation" => true }, "status" => 500 })
    page = api("GET", "/folders/dir", { "per_page" => 1 })
    assert_equal 500, api("GET", "/folders/dir", { "per_page" => 1, "cursor" => page.headers["x-files-cursor"] }).status
  end

  # An empty page with a new cursor must not end a listing; one that repeats the cursor it was sent
  # makes no progress, which a client has to detect.
  def test_empty_pages_continue_with_a_new_cursor_or_repeat_the_one_sent
    reset({ "groups" => (1..3).map { |number| { "name" => "g#{number}" } } })
    add_fault({ "operation" => "groups.list", "match" => { "continuation" => true }, "kind" => "empty_page" })
    first = api("GET", "/groups", { "per_page" => 2 })
    empty = api("GET", "/groups", { "per_page" => 2, "cursor" => first.headers["x-files-cursor"] })
    assert_equal [ 200, [] ], [ empty.status, empty.json ]
    refute_equal first.headers["x-files-cursor"], empty.headers["x-files-cursor"]
    last = api("GET", "/groups", { "per_page" => 2, "cursor" => empty.headers["x-files-cursor"] })
    assert_equal [ %w[g3], nil ], [ last.json.map { |group| group["name"] }, last.headers["x-files-cursor"] ]

    add_fault({ "operation" => "groups.list", "match" => { "continuation" => true }, "kind" => "empty_page", "cursor" => "repeat" })
    repeated = api("GET", "/groups", { "per_page" => 2, "cursor" => first.headers["x-files-cursor"] })
    assert_equal [ [], first.headers["x-files-cursor"] ], [ repeated.json, repeated.headers["x-files-cursor"] ]
    assert_equal 400, control("POST", "faults", { "operation" => "groups.find", "kind" => "empty_page" }).status
  end

  # A delay before holds the request, outside the simulator's lock, before it is applied; a delay
  # after applies it at once and holds only the response.
  def test_delays_hold_a_request_before_it_is_applied_or_its_response_after
    add_fault({ "operation" => "groups.create", "kind" => "delay", "delay_ms" => 1_000 })
    started = now
    held = Thread.new { api("POST", "/groups", { "name" => "late" }) }
    wait_until { control("GET", "faults").json["faults"].first["consumed_by_request"] }
    # Other requests are answered, and the held one has not changed anything yet.
    assert_equal [], api("GET", "/groups").json
    assert held.alive?
    assert_equal 201, held.value.status
    assert_operator now - started, :>=, 1.0
    assert_equal [ [ 201, "delay", 1_000 ] ], journaled("groups.create", %w[status fault_kind delay_ms])

    add_fault({ "operation" => "groups.find", "kind" => "delay", "delay_ms" => 1_000, "when" => "after" })
    started = now
    answered = Thread.new { api("PATCH", "/groups/1", { "name" => "x" }) && api("GET", "/groups/1") }
    wait_until { journal.any? { |entry| entry["operation"] == "groups.find" } }
    assert answered.alive?
    assert_equal [ 200, "x" ], [ answered.value.status, answered.value.json["name"] ]
    assert_operator now - started, :>=, 1.0
  end

  # A hold may pass a client's default read timeout, and is bounded: explicit rules only, at most
  # MAX_HOLD_MS long, at most MAX_HOLDS pending or holding a request. It applies the request once it
  # ends, and a reset ends it at once, the request then refused as stale.
  def test_holds_are_bounded_and_end_when_they_elapse_or_a_reset_starts_a_new_state
    limits = control("GET", "ready").json["faults"]
    assert_equal [ 120_000, 2 ], limits.values_at("max_hold_ms", "max_holds")
    {
      { "delay_ms" => 120_001 } => "delay_ms must be a whole number of milliseconds from 1 to 120000",
      { "delay_ms" => 10, "random" => { "seed" => "s", "rate" => 1 } } => "hold rules are explicit; random does not apply to them",
      { "delay_ms" => 10, "when" => "after" } => "when do not apply to hold faults",
    }.each do |fields, error|
      refused = control("POST", "faults", { "operation" => "groups.create", "kind" => "hold" }.merge(fields))
      assert_equal [ 400, error ], [ refused.status, refused.json["error"] ]
    end

    add_fault({ "operation" => "groups.create", "kind" => "hold", "delay_ms" => 300 })
    started = now
    assert_equal 201, api("POST", "/groups", { "name" => "late" }).status
    assert_operator now - started, :>=, 0.3
    entry = journal.find { |candidate| candidate["operation"] == "groups.create" }
    assert_equal [ 201, "hold", 300, "elapsed" ], entry.values_at("status", "fault_kind", "hold_ms", "hold_ended")
    assert_operator entry["held_ms"], :>=, 300

    2.times { |index| add_fault({ "operation" => "groups.find", "match" => { "id" => index + 1 }, "kind" => "hold", "delay_ms" => 120_000 }) }
    third = control("POST", "faults", { "operation" => "groups.list", "kind" => "hold", "delay_ms" => 1 })
    assert_equal [ 409, "At most 2 hold rules can be pending or holding a request at once" ], [ third.status, third.json["error"] ]
    held = Thread.new { api("GET", "/groups/1") }
    wait_until { control("GET", "faults").json["faults"].any? { |rule| rule["operation"] == "groups.find" && rule["consumed_by_request"] } && held.alive? }
    started = now
    reset
    assert_equal [ 409, "simulation/stale-request" ], [ held.value.status, held.value.json["type"] ]
    assert_operator now - started, :<, 2
  end

  # A selected hold keeps its rule's place while its request is held, not only while the rule is
  # pending: with two requests held and no hold rule pending, a third hold rule is still refused, and
  # control requests answer meanwhile. The places come back when the requests end, whether they
  # elapse, are refused as stale after a reset, or fail with an exception, and can be taken again.
  def test_requests_being_held_keep_their_rules_places_until_they_end
    holding = -> { control("GET", "faults").json.values_at("pending", "holding") }
    2.times { |index| add_fault({ "operation" => "groups.find", "match" => { "id" => index + 1 }, "kind" => "hold", "delay_ms" => 120_000 }) }
    assert_equal [ 2, 0 ], holding.call
    held = [ 1, 2 ].map { |id| Thread.new { api("GET", "/groups/#{id}") } }
    wait_until { holding.call == [ 0, 2 ] }
    third = control("POST", "faults", { "operation" => "groups.list", "kind" => "hold", "delay_ms" => 1 })
    assert_equal [ 409, "At most 2 hold rules can be pending or holding a request at once" ], [ third.status, third.json["error"] ]
    assert_equal [ 200, 200 ], [ control("GET", "ready").status, control("GET", "journal").status ]
    assert held.all?(&:alive?)

    reset
    assert_equal([ [ 409, "simulation/stale-request" ] ] * 2, held.map { |thread| [ thread.value.status, thread.value.json["type"] ] })
    assert_equal [ 0, 0 ], holding.call

    # A request whose hold ends in an exception gives its place back too.
    add_fault({ "operation" => "groups.create", "kind" => "hold", "delay_ms" => 60_000 })
    broken = Object.new
    def broken.to_io = raise(IOError, "the connection's socket is gone")
    error = assert_raises(IOError) { request(app, "POST", "/api/rest/v1/groups", JSON.generate({ "name" => "x" }), { "puma.socket" => broken }) }
    assert_equal "the connection's socket is gone", error.message
    assert_equal [ 0, 0 ], holding.call

    add_fault({ "operation" => "groups.create", "kind" => "hold", "delay_ms" => 50 })
    assert_equal 201, api("POST", "/groups", { "name" => "elapsed" }).status
    assert_equal [ 0, 0 ], holding.call
    2.times { |index| add_fault({ "operation" => "groups.find", "match" => { "id" => index + 1 }, "kind" => "hold", "delay_ms" => 1 }) }
    assert_equal [ 2, 0 ], holding.call
  end

  def test_connection_faults_are_not_consumed_by_a_server_that_cannot_hijack
    add_fault({ "operation" => "users.list", "kind" => "drop_before" })
    refused = api("GET", "/users")
    assert_equal [ 501, "simulation/not-supported" ], [ refused.status, refused.json["type"] ]
    assert_match(/bundle exec puma/, refused.json["error"])
    assert_equal [ "pending", 0 ], control("GET", "faults").json["faults"].first.values_at("state", "matched_requests")
    assert_equal [ [ 501, 1, nil ] ], journaled("users.list", %w[status fault_unavailable fault_id])
  end

  # The same requests per key get the same decisions however requests for other keys interleave,
  # after a reset and on another simulator.
  def test_random_faults_replay_the_same_schedule_in_any_interleaving
    rule = { "operation" => "groups.update", "random" => { "seed" => "replay-1", "rate" => 0.5, "key" => [ "id" ] }, "status" => 503 }
    by_key = lambda do |order, to: app|
      reset({ "groups" => (1..3).map { |number| { "name" => "g#{number}" } } }, to:)
      add_fault(rule, to:)
      order.each_with_object(Hash.new { |hash, key| hash[key] = [] }) { |id, results| results[id] << api("PATCH", "/groups/#{id}", { "name" => "n" }, to:).status }
    end
    grouped = by_key.call(([ 1 ] * 6) + ([ 2 ] * 6) + ([ 3 ] * 6))
    interleaved = by_key.call([ 1, 2, 3 ] * 6)
    assert_equal grouped, interleaved
    assert_equal grouped, by_key.call([ 3, 1, 2 ] * 6, to: new_app)
    assert_equal [ 200, 503 ], grouped.values.flatten.uniq.sort

    schedule = control("GET", "faults").json["faults"].first.dig("random", "schedule")
    assert_equal 18, schedule.size
    assert_equal(grouped[2], schedule.select { |decision| decision["key"] == { "id" => 2 } }.sort_by { |decision| decision["attempt"] }
                                     .map { |decision| decision["outcome"] == "fault" ? 503 : 200 }
    )
  end

  # At the budget, selection stays stable but which selected request is failed follows arrival
  # order: the budget belongs to the whole rule. The schedule shows both.
  def test_a_random_rules_budget_is_spent_in_arrival_order_while_selection_stays_stable
    rule = { "operation" => "groups.update", "random" => { "seed" => "budget", "rate" => 1, "key" => [ "id" ], "max_faults" => 1 }, "status" => 503 }
    runs = [ [ 1, 2 ], [ 2, 1 ] ].to_h do |order|
      reset({ "groups" => [ { "name" => "a" }, { "name" => "b" } ] })
      add_fault(rule)
      statuses = order.to_h { |id| [ id, api("PATCH", "/groups/#{id}", { "name" => "n" }).status ] }
      schedule = control("GET", "faults").json["faults"].first["random"]
      [ order, [ statuses, schedule["schedule"].to_h { |entry| [ entry.dig("key", "id"), entry.values_at("selected", "outcome") ] }, schedule["outcomes"] ] ]
    end
    assert_equal [ { 1 => 503, 2 => 200 }, { 1 => [ true, "fault" ], 2 => [ true, "budget-exhausted" ] } ], runs[[ 1, 2 ]].first(2)
    assert_equal [ { 2 => 503, 1 => 200 }, { 2 => [ true, "fault" ], 1 => [ true, "budget-exhausted" ] } ], runs[[ 2, 1 ]].first(2)
    assert_equal({ "pass" => 0, "fault" => 1, "overridden" => 0, "unavailable" => 0, "budget-exhausted" => 1 }, runs[[ 1, 2 ]].last)
  end

  def test_explicit_rules_take_precedence_over_random_rules
    reset({ "groups" => [ { "name" => "a" } ] })
    add_fault({ "operation" => "groups.find", "random" => { "seed" => "s", "rate" => 1, "max_faults" => 2 }, "status" => 500 })
    add_fault({ "operation" => "groups.find", "status" => 404 })
    assert_equal([ 404, 500, 500, 200 ], 4.times.map { api("GET", "/groups/1").status })
    random, explicit = control("GET", "faults").json["faults"]
    assert_equal [ "exhausted", 2, 1 ], [ random["state"], random.dig("random", "faulted"), random.dig("random", "outcomes", "overridden") ]
    assert_equal(%w[overridden fault fault budget-exhausted], random.dig("random", "schedule").map { |decision| decision["outcome"] })
    assert_equal "consumed", explicit["state"]
    assert_equal [ [ 404, 2 ], [ 500, 1 ], [ 500, 1 ], [ 200, nil ] ], journaled("groups.find", %w[status fault_id])
  end

  def test_random_rules_can_key_on_the_session_without_reporting_its_credential
    credentials = %w[alpha-sentinel beta-sentinel]
    decide = lambda do
      reset({ "groups" => [ { "name" => "a" } ] })
      add_fault({ "operation" => "groups.find", "random" => { "seed" => "sessions", "rate" => 0.5, "key" => [ "session" ] }, "status" => 503 })
      (credentials * 4).map { |credential| request(app, "GET", "/api/rest/v1/groups/1", nil, "HTTP_X_FILESAPI_KEY" => credential).status }
    end
    first = decide.call
    assert_equal first, decide.call
    faults = control("GET", "faults")
    assert_equal([ 1, 2 ], faults.json["faults"].first.dig("random", "schedule").map { |decision| decision.dig("key", "session") }.uniq)
    [ faults.body, control("GET", "journal").body ].each { |body| credentials.each { |credential| refute_includes body, credential } }
  end

  def test_fault_rules_refuse_fields_that_do_not_apply
    [
      { "operation" => "users.list", "kind" => "delay", "status" => 503, "delay_ms" => 5 },
      { "operation" => "users.list", "kind" => "delay" },
      { "operation" => "users.list", "kind" => "delay", "delay_ms" => 10_001 },
      { "operation" => "transfers.download", "kind" => "truncate" },
      { "operation" => "transfers.download", "kind" => "excess_body", "bytes" => 0 },
      { "operation" => "users.list", "kind" => "html_page" },
      { "operation" => "users.list", "kind" => "expired_url" },
      { "operation" => "users.list", "kind" => "teleport" },
      { "operation" => "users.list", "status" => 503, "when" => "after" },
      { "operation" => "users.list", "status" => 503, "type" => "Not Found" },
      { "operation" => "users.list", "kind" => "unstructured", "status" => 503, "type" => "not-found" },
      { "operation" => "users.list", "status" => 503, "random" => { "seed" => "s", "rate" => 0 } },
      { "operation" => "users.list", "status" => 503, "random" => { "seed" => "s", "rate" => 0.5, "key" => [ "id" ] } },
      { "operation" => "users.list", "status" => 503, "random" => { "seed" => "s", "rate" => 0.5 }, "attempt" => 2 },
      { "operation" => "users.list", "status" => 503, "match" => { "continuation" => "yes" } },
      { "operation" => "users.list", "kind" => "redirect" },
      { "operation" => "users.list", "kind" => "redirect", "location" => "http://127.0.0.1:4099/elsewhere" },
      { "operation" => "users.list", "kind" => "redirect", "location" => "http://127.0.0.1:4099", "status" => 500 },
      { "operation" => "users.list", "status" => 500, "location" => "http://127.0.0.1:4099" }
    ].each do |rule|
      response = control("POST", "faults", rule)
      assert_equal [ 400, "simulation/invalid-control-request" ], [ response.status, response.json["type"] ], rule.inspect
    end
    # Random rules may overlap each other and explicit rules.
    add_fault({ "operation" => "users.list", "status" => 503 })
    add_fault({ "operation" => "users.list", "status" => 500, "random" => { "seed" => "s", "rate" => 0.5 } })
    add_fault({ "operation" => "users.list", "status" => 500, "random" => { "seed" => "t", "rate" => 0.5 } })
    assert_equal [ 1, 0, 2 ], control("GET", "faults").json.values_at("pending", "consumed", "random")
  end

  private

  def now
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  def wait_until(timeout = 5)
    deadline = now + timeout
    until yield
      raise "condition not met within #{timeout}s" if now > deadline

      Thread.pass
    end
  end
end
