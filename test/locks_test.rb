require_relative "test_helper"

# Advisory locks (/locks/{path}): their public lifecycle, the flags a public request must send, the
# locks each lock conflicts with and lists beside, expiry on the lock clock as distinct from cleanup,
# and that locks never change what file operations do.
class LocksTest < Minitest::Test
  include SimulationRequests
  include FileRequests

  PUBLIC_FLAGS = { "allow_access_by_any_user" => true, "exclusive" => true }.freeze
  UUID = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  def setup
    @app = new_app
  end

  def test_a_lock_is_created_listed_and_released_with_its_token
    created = lock("docs/report.txt", "timeout" => 60)
    assert_equal 201, created.status, created.body
    token = created.json["token"]
    assert_match UUID, token
    expected = { "path" => "docs/report.txt", "timeout" => 60, "depth" => "infinity", "recursive" => true, "scope" => "exclusive", "exclusive" => true,
                 "token" => token, "type" => "office", "allow_access_by_any_user" => true, "user_id" => -1 }
    assert_equal expected, created.json
    assert_equal [ created.json ], api("GET", "/locks/docs/report.txt").json
    assert_equal 204, release("docs/report.txt", token).status
    assert_equal [], api("GET", "/locks/docs/report.txt").json
    again = release("docs/report.txt", token)
    assert_equal [ 404, "not-found", "not-found" ], [ again.status, again.json["type"], again.headers["x-files-error-class"] ]
    journaled = journal.map { |entry| entry.values_at("operation", "status", "lock") }
    assert_equal [ [ "locks.create", 201, 1 ], [ "locks.list_for", 200, nil ], [ "locks.delete", 204, 1 ], [ "locks.list_for", 200, nil ], [ "locks.delete", 404, nil ] ], journaled
  end

  # Without the internal token, type or scope, a lock is created only when both public flags are
  # true; any other combination is refused before the locks it would conflict with are considered.
  # A flag of the wrong type is refused first, as a type error.
  def test_only_both_public_flags_true_create_a_lock
    lock("held.txt")
    required = "Required request parameter missing: token, allow_access_by_any_user, or exclusive"
    [ { "allow_access_by_any_user" => true, "exclusive" => false }, { "allow_access_by_any_user" => false, "exclusive" => true },
      { "allow_access_by_any_user" => false, "exclusive" => false }, { "allow_access_by_any_user" => true }, { "exclusive" => true }, {},
      { "allow_access_by_any_user" => nil, "exclusive" => true }, { "allow_access_by_any_user" => "false", "exclusive" => "true" } ].each do |flags|
      refused = api("POST", "/locks/held.txt", flags)
      assert_equal [ 422, "bad-request/request-params-required", required, "bad-request/request-params-required" ],
                   [ refused.status, refused.json["type"], refused.json["error"], refused.headers["x-files-error-class"] ], flags.inspect
    end
    mistyped = api("POST", "/locks/held.txt", { "allow_access_by_any_user" => false, "exclusive" => "maybe" })
    assert_equal [ 422, "bad-request", "exclusive is invalid" ], [ mistyped.status, mistyped.json["type"], mistyped.json["error"] ]
    assert_equal 201, api("POST", "/locks/other.txt", { "allow_access_by_any_user" => "true", "exclusive" => "true" }).status, "form-style strings"
    assert_equal %w[held.txt], listed("held.txt")
  end

  # The model's timeout: 12 hours by default and for zero or less, at most a week.
  def test_timeouts_default_and_clamp_as_the_model_does
    { nil => 43_200, 0 => 43_200, -5 => 43_200, 1 => 1, 604_800 => 604_800, 604_801 => 604_800 }.each_with_index do |(timeout, expected), index|
      params = timeout.nil? ? {} : { "timeout" => timeout }
      assert_equal expected, lock("t/#{index}", params).json["timeout"], timeout.inspect
    end
    assert_equal [ 422, "timeout is invalid" ], lock("t/x", "timeout" => "soon").json.values_at("http-code", "error")
    shallow = lock("t/shallow", "recursive" => false).json
    assert_equal [ false, "0" ], shallow.values_at("recursive", "depth")
  end

  # A new lock is exclusive, so it conflicts with every lock the model's validation compares it with:
  # the live locks at its path, each lock at a folder above it that applies to subfolders, and, when
  # it applies to its own subfolders, everything in its range: the path's own locks again, those
  # inside it and those at names that only start with it. A lock above that does not apply to
  # subfolders, and a name that only starts with a folder above, never conflict.
  def test_exclusive_locks_conflict_as_the_model_queries_them
    root = lock("a").json["token"]
    refused = lock("a")
    assert_equal [ 422, "processing-failure/resource-locked", "exclusive lock #{root} at /a, exclusive lock #{root} at /a" ], [ refused.status, refused.json["type"], refused.json["error"] ],
                 "a live lock at the path is a sibling and in the range"
    assert_equal "processing-failure/resource-locked", refused.headers["x-files-error-class"]
    assert_equal "exclusive lock #{root} at /a", lock("a", "recursive" => false).json["error"], "without subfolders, the sibling alone"
    assert_equal "exclusive lock #{root} at /a", lock("a/b/c").json["error"], "a recursive lock above"
    shallow = lock("x", "recursive" => false).json["token"]
    y = lock("x/y").json["token"]
    assert_match UUID, y, "a lock above that does not apply to subfolders is not in the way"
    z = lock("x/z/deep").json["token"]
    # The sibling, then the range in index order: x/y and x/z/deep sort before x itself ("/" < ":").
    assert_equal "exclusive lock #{shallow} at /x, exclusive lock #{y} at /x/y, exclusive lock #{z} at /x/z/deep, exclusive lock #{shallow} at /x", lock("x").json["error"]
    prefixed = lock("q2").json["token"]
    assert_equal "exclusive lock #{prefixed} at /q2", lock("q").json["error"], "q2 is in q's range"
    assert_equal 201, lock("q", "recursive" => false).status, "a lock that does not apply to subfolders has no range"
    lock("p2")
    assert_equal 201, lock("p/c").status, "p2 is not above p/c: the model looks up each folder above by its own name"
  end

  # A path's list holds its own live locks and those of each folder above it that apply to
  # subfolders. With include_children it holds the path's range instead of its own locks, no more
  # than one level deeper than the path: the locks one level inside it and those at names that only
  # start with it, and one level inside those. Always in path order. The model's lookup at a path
  # also finds a lock at the path followed by a colon.
  def test_lists_hold_the_path_its_recursive_ancestors_and_its_shallow_range
    lock("c", "recursive" => false)
    lock("c/one", "recursive" => false)
    lock("c/one/deep")
    lock("c2", "recursive" => false)
    lock("c2/two", "recursive" => false)
    lock("c2/two/deeper")
    lock("r")
    lock("k:v")
    assert_equal %w[c], listed("c")
    assert_equal %w[c c/one c2 c2/two], listed("c", { "include_children" => true })
    assert_equal %w[c/one c/one/deep], listed("c/one", { "include_children" => "true" })
    assert_equal [], listed("c/two"), "a lock above that does not apply to subfolders is not listed"
    assert_equal %w[r], listed("r/s/t"), "a recursive lock above is"
    assert_equal %w[k:v], listed("k"), "the lookup at k finds the lock at k:v"
    assert_equal [ 422, "include_children is invalid" ], api("GET", "/locks/c", { "include_children" => "sometimes" }).json.values_at("http-code", "error")
  end

  # The action answers the whole sorted list: cursor and per_page are checked as declared (a string
  # and a whole number) and change nothing, and no cursor comes back.
  def test_a_lock_list_is_the_whole_answer_whatever_the_paging_parameters
    lock("p", "recursive" => false)
    lock("p/q")
    everything = listed("p", { "include_children" => true })
    assert_equal %w[p p/q], everything
    [ { "per_page" => 1 }, { "per_page" => 0 }, { "per_page" => -3 }, { "cursor" => "abc" }, { "cursor" => "", "per_page" => 100_000 } ].each do |paging|
      response = api("GET", "/locks/p", paging.merge("include_children" => true))
      assert_equal 200, response.status, "#{paging.inspect}: #{response.body}"
      assert_equal [ everything, nil ], [ response.json.map { |held| held["path"] }, response.headers["x-files-cursor"] ], paging.inspect
    end
    assert_equal [ 422, "per_page is invalid" ], api("GET", "/locks/p", { "per_page" => "many" }).json.values_at("http-code", "error")
  end

  # Expiry is logical: past its deadline on the lock clock (a deadline equal to the clock is still
  # live) a lock is no longer listed, releasable or a sibling, but it stays held and still conflicts
  # through the model's ancestor and range queries until a cleanup removes it: as a recursive
  # ancestor, as a lock inside a recursive new lock, and at a recursive new lock's own path.
  def test_expiry_leaves_conflicts_above_and_below_until_cleanup
    edge = lock("edge", "timeout" => 60).json["token"]
    above = lock("old", "timeout" => 30).json["token"]
    below = lock("tree/leaf", "timeout" => 30).json["token"]
    assert_equal({ "epoch" => 0, "clock_seconds" => 60 }, advance(60).json)
    assert_equal %w[edge], listed("edge"), "a deadline equal to the clock is live"
    advance(1)
    assert_equal [], api("GET", "/locks/edge").json
    assert_equal 404, release("edge", edge).status
    assert_equal [ 3, 3 ], control("GET", "ready").json["locks"].values_at("held", "expired")
    assert_equal "exclusive lock #{above} at /old", lock("old/new").json["error"], "an expired recursive ancestor still conflicts"
    assert_equal "exclusive lock #{below} at /tree/leaf", lock("tree").json["error"], "an expired descendant still conflicts"
    assert_equal "exclusive lock #{edge} at /edge", lock("edge").json["error"], "an expired lock at the path is still in a recursive new lock's range"
    assert_equal 201, lock("edge", "recursive" => false).status, "a lock without subfolders has no range, and an expired lock is no sibling"

    assert_equal({ "epoch" => 0, "removed" => 3, "held" => 1 }, control("POST", "locks/cleanup", {}).json)
    assert_equal [ 201, 201 ], [ lock("old/new").status, lock("tree").status ]
    assert_equal [ 3, 0 ], control("GET", "ready").json["locks"].values_at("held", "expired")
    [ {}, { "advance_seconds" => 0 }, { "advance_seconds" => "1" }, { "advance_seconds" => 1, "freeze" => true } ].each do |body|
      assert_equal 400, advance_with(body).status, body.inspect
    end
    assert_equal 400, control("POST", "locks/cleanup", { "all" => true }).status
  end

  # Held locks, expired ones included until a cleanup, count against FILES_MOCK_MAX_RECORDS; a reset
  # empties them and starts the clock again.
  def test_held_locks_are_bounded_and_a_reset_replaces_them
    @app = new_app(max_records: 2)
    first = lock("one", "timeout" => 1).json["token"]
    lock("two", "timeout" => 1)
    assert_equal [ 409, "simulation/limit-exceeded" ], lock("three").json.values_at("http-code", "type")
    advance(2)
    assert_equal 409, lock("three").status, "expired locks are held until a cleanup"
    control("POST", "locks/cleanup", {})
    assert_equal 201, lock("three").status
    reset
    assert_equal [ 0, 0 ], control("GET", "ready").json["locks"].values_at("held", "clock_seconds")
    assert_equal 404, release("one", first).status
    assert_equal [], api("GET", "/locks/three").json
  end

  # A token releases only its own lock at its own path. Internal lock parameters are refused, not
  # ignored. Every identity is the same synthetic site: a lock made with one API key is listed and
  # released with another, and the journal numbers identities without authorizing them.
  def test_a_token_releases_only_its_own_lock_and_internal_parameters_are_refused
    one = lock("one").json["token"]
    two = lock("two").json["token"]
    assert_equal [ 404, 404 ], [ release("one", two).status, release("two", one).status ]
    assert_equal [ 422, "token is missing" ], api("DELETE", "/locks/one").json.values_at("http-code", "error")
    [ api("POST", "/locks/three", PUBLIC_FLAGS.merge("token" => "a-token-of-my-own")), api("POST", "/locks/three", { "type" => "office", "scope" => "exclusive" }),
      api("POST", "/locks/three", PUBLIC_FLAGS.merge("owner" => "someone")), api("GET", "/locks/one", { "bundle_registration_code" => "x" }),
      api("DELETE", "/locks/one", { "token" => one, "bundle_registration_code" => "x" }) ].each do |refused|
      assert_equal [ 501, "simulation/not-supported" ], [ refused.status, refused.json["type"] ], refused.body
    end
    listed = request(app, "GET", "/api/rest/v1/locks/one", nil, { "HTTP_X_FILESAPI_KEY" => "second-key" })
    assert_equal([ one ], listed.json.map { |held| held["token"] })
    released = request(app, "DELETE", "/api/rest/v1/locks/one?token=#{one}", nil, { "HTTP_X_FILESAPI_KEY" => "second-key" })
    assert_equal 204, released.status
    assert_equal [ { "api_key" => 1 } ], journal.filter_map { |entry| entry["credentials"] }.uniq
    assert_equal 501, api("POST", "/locks/", PUBLIC_FLAGS).status, "the root is not a lock path"
    colon = lock("m:n").json["token"]
    assert_equal 204, release("m", colon).status, "the model's lookup at m also finds the lock at m:n"
  end

  # A lock's path follows the API's request-path rules for a route other than the folders endpoints:
  # a folder name ending in whitespace is refused, then a zero-width space anywhere, and the lock's own
  # name may end in whitespace. Declared parameters, and on a create the public flags, come first.
  def test_lock_paths_follow_the_apis_request_path_rules
    token = lock("kept").json["token"]
    { "bad-request/path-cannot-have-trailing-whitespace" => [ "a /b", "kept\t/c" ], "bad-request/invalid-path" => [ "zero\u200Bwidth", "kept/\u200B" ] }.each do |type, paths|
      paths.each do |path|
        [ lock(path), api("GET", "/locks/#{route(path)}"), release(path, token) ].each do |refused|
          assert_equal [ 422, type, type ], [ refused.status, refused.json["type"], refused.headers["x-files-error-class"] ], path.inspect
        end
      end
    end
    assert_equal 1, control("GET", "ready").json["locks"]["held"]
    spaced = route("a /b")
    assert_equal [ 422, "bad-request/request-params-required" ], api("POST", "/locks/#{spaced}", { "exclusive" => true }).json.values_at("http-code", "type")
    assert_equal [ 422, "include_children is invalid" ], api("GET", "/locks/#{spaced}", { "include_children" => "sometimes" }).json.values_at("http-code", "error")
    missing = api("DELETE", "/locks/#{spaced}")
    assert_equal [ 422, "bad-request", "token is missing", "bad-request" ], [ missing.status, missing.json["type"], missing.json["error"], missing.headers["x-files-error-class"] ]
    # A token sent null or empty passes the parameter validation: the path rules answer, and at a valid
    # path no lock has that token.
    [ { "token" => nil }, { "token" => "" } ].each do |sent|
      assert_equal([ 422, "bad-request/path-cannot-have-trailing-whitespace" ], api("DELETE", "/locks/#{spaced}", sent).then { |refused| [ refused.status, refused.headers["x-files-error-class"] ] }, sent.inspect)
      assert_equal([ 404, "not-found" ], api("DELETE", "/locks/kept", sent).then { |refused| [ refused.status, refused.headers["x-files-error-class"] ] }, sent.inspect)
    end
    assert_equal 1, control("GET", "ready").json["locks"]["held"]

    trailing = lock("a/b ")
    assert_equal [ 201, "a/b " ], [ trailing.status, trailing.json["path"] ]
    assert_equal [ "a/b " ], listed("a/b ")
    assert_equal 204, release("a/b ", trailing.json["token"]).status
  end

  # A schema subset without every lock operation and the Lock object simulates no lock at all, as
  # the generated inventory says, so readiness never names an operation the server refuses.
  def test_a_schema_without_every_lock_operation_simulates_no_locks
    schema = JSON.parse(File.read(FilesMockServer::Simulation::SCHEMA_PATH))
    Tempfile.create([ "schema", ".json" ]) do |file|
      file.write(JSON.generate(schema.merge("operations" => schema["operations"].except("locks.create"))))
      file.flush
      partial = Rack::Lint.new(FilesMockServer::Simulation::App.new(schema_path: file.path, transfer_origin: SimulationRequests::ORIGIN))
      ready = control("GET", "ready", to: partial).json
      assert_equal [ [], nil ], [ ready["operations"].map { |operation| operation["id"] }.grep(/\Alocks\./), ready["locks"] ]
      assert_equal [ 501, 404 ], [ api("GET", "/locks/a", to: partial).status, control("POST", "locks/clock", { "advance_seconds" => 1 }, to: partial).status ]
    end
  end

  # Locks are advisory: writing, moving and deleting a locked file all proceed, and the lock stays at
  # its path afterwards.
  def test_locks_never_change_what_file_operations_do
    upload("docs/a.txt", [ "first" ])
    token = lock("docs/a.txt").json["token"]
    lock("docs/archive", "recursive" => true)
    assert_equal 200, upload("docs/a.txt", [ "second" ]).status, "overwrite"
    moved = api("POST", "/file_actions/move/docs/a.txt", { "destination" => "docs/archive/a.txt" })
    assert_equal 201, moved.status, moved.body
    assert_equal "second", download("docs/archive/a.txt").body
    assert_equal 204, api("DELETE", "/files/docs/archive/a.txt").status
    assert_equal [ "docs/a.txt" ], listed("docs/a.txt"), "the lock stays where it was made"
    assert_equal [ "docs/archive" ], listed("docs/archive/a.txt")
    assert_equal 204, release("docs/a.txt", token).status
  end

  # The same lifecycle over a real Puma process, with the form body the Ruby SDK sends and the lock
  # clock and cleanup controls over HTTP.
  def test_the_lifecycle_works_over_http
    server = ServerProcess.start({ "FILES_MOCK_MODE" => "simulation" })
    status, created = form(server, "/api/rest/v1/locks/shared%20docs/plan.txt", "allow_access_by_any_user=true&exclusive=true&timeout=10")
    assert_equal [ 201, "shared docs/plan.txt", 10 ], [ status, created["path"], created["timeout"] ]
    status, listed = server.json("GET", "/api/rest/v1/locks/shared%20docs?include_children=true")
    assert_equal [ 200, [ created ] ], [ status, listed ]
    response = server.request("POST", "/api/rest/v1/locks/shared%20docs", { "allow_access_by_any_user" => true, "exclusive" => true })
    assert_equal [ "422", "processing-failure/resource-locked" ], [ response.code, response["x-files-error-class"] ]
    assert_equal 200, server.request("POST", "/__files_mock/v1/locks/clock", { "advance_seconds" => 11 }).code.to_i
    assert_equal [], server.json("GET", "/api/rest/v1/locks/shared%20docs/plan.txt").last
    assert_equal "404", server.request("DELETE", "/api/rest/v1/locks/shared%20docs/plan.txt?token=#{created["token"]}").code
    assert_equal({ "epoch" => 0, "removed" => 1, "held" => 0 }, server.json("POST", "/__files_mock/v1/locks/cleanup", {}).last)
  ensure
    server&.stop
  end

  private

  def lock(path, params = {})
    api("POST", "/locks/#{route(path)}", PUBLIC_FLAGS.merge(params))
  end

  # The paths of the locks the list for `path` answers, in order.
  def listed(path, params = nil)
    api("GET", "/locks/#{route(path)}", params).json.map { |held| held["path"] }
  end

  def release(path, token)
    api("DELETE", "/locks/#{route(path)}", { "token" => token })
  end

  def advance(seconds)
    advance_with({ "advance_seconds" => seconds })
  end

  def advance_with(body)
    control("POST", "locks/clock", body)
  end

  def form(server, path, body)
    response = Net::HTTP.start("127.0.0.1", server.port) { |http| http.post(path, body, { "Content-Type" => "application/x-www-form-urlencoded" }) }
    [ response.code.to_i, JSON.parse(response.body) ]
  end
end
