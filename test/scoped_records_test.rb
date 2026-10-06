require_relative "test_helper"

# Records beyond the plain collection/member shape: id-less records, records found by their own
# fields, structural scopes and the lists scoped to them, path-keyed records, fixture responses,
# file and folder metadata, file parameters (attachments), external destinations and cursors with
# special characters.
class ScopedRecordsTest < Minitest::Test
  include SimulationRequests
  include FileRequests

  def setup
    @app = new_app
  end

  # Recipients have no id: they are kept in order under the bundle they were created for, which is
  # never looked up, and listed only for that bundle.
  def test_id_less_records_are_kept_in_order_under_their_structural_scope
    first = api("POST", "/bundle_recipients", { "bundle_id" => 7, "recipient" => "a@example.com", "name" => "A" })
    assert_equal [ 201, { "recipient" => "a@example.com", "name" => "A" } ], [ first.status, first.json ]
    api("POST", "/bundle_recipients", { "bundle_id" => 8, "recipient" => "b@example.com" })
    api("POST", "/bundle_recipients", { "bundle_id" => 7, "recipient" => "c@example.com" })
    assert_equal(%w[a@example.com c@example.com], api("GET", "/bundle_recipients", { "bundle_id" => 7 }).json.map { |recipient| recipient["recipient"] })
    # A cursor belongs to the selection it was issued for.
    cursor = api("GET", "/bundle_recipients", { "bundle_id" => 7, "per_page" => 1 }).headers["x-files-cursor"]
    assert_equal([ "c@example.com" ], api("GET", "/bundle_recipients", { "bundle_id" => 7, "per_page" => 1, "cursor" => cursor }).json.map { |recipient| recipient["recipient"] })
    crossed = api("GET", "/bundle_recipients", { "bundle_id" => 8, "per_page" => 1, "cursor" => cursor })
    assert_equal [ 422, "bad-request/invalid-cursor" ], [ crossed.status, crossed.json["type"] ]
    {
      "the scope is required" => [ api("GET", "/bundle_recipients"), 422 ],
      "acting as another user" => [ api("GET", "/bundle_recipients", { "bundle_id" => 7, "user_id" => 2 }), 501 ],
      "sending share email" => [ api("POST", "/bundle_recipients", { "bundle_id" => 7, "recipient" => "d@example.com", "share_after_create" => true }), 501 ],
    }.each { |name, (response, status)| assert_equal status, response.status, name }
  end

  # A list that requires its parent answers only that parent's records, and its cursors only that
  # selection: an automation run's automation_id is one of its fields, while the export results' parent
  # ids are not, so fixtures give them with _scope and they are never returned. No parent is checked
  # to exist, and filters, sorts and acting as another user are still refused.
  def test_lists_that_require_their_parent_answer_only_that_parents_records
    reset({ "automation_runs" => [ { "automation_id" => 1, "version" => 3 }, { "automation_id" => 2 }, { "automation_id" => 1 } ],
            "history_export_results" => [ { "path" => "a", "_scope" => { "history_export_id" => 5 } }, { "path" => "b", "_scope" => { "history_export_id" => 6 } }, { "path" => "c" } ],
            "action_notification_export_results" => [ { "path" => "x", "_scope" => { "action_notification_export_id" => 9 } }, { "path" => "y" } ] }
         )
    ids = ->(path, params) { api("GET", path, params).json.map { |record| record["id"] } }
    assert_equal([ [ 1, 3 ], [ 2 ], [] ], [ 1, 2, 3 ].map { |automation| ids.call("/automation_runs", { "automation_id" => automation }) })
    assert_equal [ { "id" => 1, "path" => "a" } ], api("GET", "/history_export_results", { "history_export_id" => 5 }).json
    assert_equal [ [ 2 ], [ 1 ], [] ], [ ids.call("/history_export_results", { "history_export_id" => 6 }), ids.call("/action_notification_export_results", { "action_notification_export_id" => 9 }),
                                         ids.call("/action_notification_export_results", { "action_notification_export_id" => 10 }) ]
    cursor = api("GET", "/automation_runs", { "automation_id" => 1, "per_page" => 1 }).headers["x-files-cursor"]
    assert_equal [ 3 ], ids.call("/automation_runs", { "automation_id" => 1, "per_page" => 1, "cursor" => cursor })
    {
      "another parent's cursor" => [ api("GET", "/automation_runs", { "automation_id" => 2, "per_page" => 1, "cursor" => cursor }), 422, "bad-request/invalid-cursor" ],
      "no parent" => [ api("GET", "/automation_runs"), 422, "bad-request" ],
      "no hidden parent" => [ api("GET", "/history_export_results"), 422, "bad-request" ],
      "a parent that is not a number" => [ api("GET", "/automation_runs", { "automation_id" => "one" }), 422, "bad-request" ],
      "a filter" => [ api("GET", "/automation_runs", { "automation_id" => 1, "filter" => { "version" => 3 } }), 501, "simulation/not-supported" ],
      "a sort" => [ api("GET", "/automation_runs", { "automation_id" => 1, "sort_by" => { "id" => "desc" } }), 501, "simulation/not-supported" ],
      "acting as another user" => [ api("GET", "/history_export_results", { "history_export_id" => 5, "user_id" => 2 }), 501, "simulation/not-supported" ],
    }.each { |name, (response, status, type)| assert_equal [ status, type ], [ response.status, response.json["type"] ], name }
    assert_equal [ "automation_id is missing", "history_export_id is missing" ], [ api("GET", "/automation_runs").json["error"], api("GET", "/history_export_results").json["error"] ]
    assert_equal({ "id" => 2, "automation_id" => 2 }, api("GET", "/automation_runs/2").json, "a run is still found by its number")

    # A fixture's hidden parent is checked as the list parameter is, and nothing else may be set with _scope.
    wrong = control("POST", "reset", { "fixtures" => { "history_export_results" => [ { "_scope" => { "history_export_id" => "five" } } ] } })
    assert_equal [ 422, "fixtures.history_export_results[0]: history_export_id is invalid" ], [ wrong.status, wrong.json["error"] ]
    other = control("POST", "reset", { "fixtures" => { "history_export_results" => [ { "_scope" => { "path" => "a" } } ] } })
    assert_equal [ 422, "fixtures.history_export_results[0]: _scope may set only history_export_id; got path" ], [ other.status, other.json["error"] ]
    assert_equal [ 1 ], ids.call("/history_export_results", { "history_export_id" => 5 }), "a refused reset changes nothing"

    # A fixture's hidden parent is kept as the number it checks to, so every spelling the list accepts
    # selects it, and only it.
    reset({ "history_export_results" => [ { "path" => "five", "_scope" => { "history_export_id" => "05" } }, { "path" => "fifty", "_scope" => { "history_export_id" => 50 } } ],
            "action_notification_export_results" => [ { "path" => "zero", "_scope" => { "action_notification_export_id" => "-0" } } ] }
         )
    paths = ->(path, params) { api("GET", path, params).json.map { |record| record["path"] } }
    assert_equal([ [ "five" ], [ "five" ], [ "fifty" ] ], %w[5 05 050].map { |parent| paths.call("/history_export_results", { "history_export_id" => parent }) })
    assert_equal([ [ "zero" ], [ "zero" ] ], %w[0 -0].map { |parent| paths.call("/action_notification_export_results", { "action_notification_export_id" => parent }) })
  end

  # A membership is found by its group_id and user_id; the path's id selects nothing.
  def test_memberships_are_found_by_their_own_fields
    api("POST", "/group_users", { "group_id" => 1, "user_id" => 2, "admin" => false })
    api("POST", "/group_users", { "group_id" => 1, "user_id" => 3 })
    api("POST", "/group_users", { "group_id" => 2, "user_id" => 2 })
    assert_equal([ 2, 3 ], api("GET", "/group_users", { "group_id" => 1 }).json.map { |membership| membership["user_id"] })
    cursor = api("GET", "/group_users", { "group_id" => 1, "per_page" => 1 }).headers["x-files-cursor"]
    assert_equal 422, api("GET", "/group_users", { "group_id" => 2, "per_page" => 1, "cursor" => cursor }).status, "a key-field selection binds its cursor too"
    updated = api("PATCH", "/group_users/99", { "group_id" => 1, "user_id" => 2, "admin" => true })
    assert_equal [ 200, { "group_id" => 1, "user_id" => 2, "admin" => true } ], [ updated.status, updated.json ]
    assert_equal 204, api("DELETE", "/group_users/5", { "group_id" => 1, "user_id" => 3 }).status
    assert_equal 404, api("DELETE", "/group_users/5", { "group_id" => 1, "user_id" => 3 }).status
    assert_equal([ [ 1, 2 ], [ 2, 2 ] ], api("GET", "/group_users").json.map { |membership| membership.values_at("group_id", "user_id") })
  end

  # A comment keeps the path it was made on, never returned or checked, and lists by that path.
  def test_comments_list_by_the_path_they_were_made_on
    api("POST", "/file_comments", { "path" => "docs/a.txt", "body" => "first" })
    api("POST", "/file_comments", { "path" => "docs/b.txt", "body" => "other" })
    api("POST", "/file_comments", { "path" => "docs/a.txt", "body" => "second" })
    listed = api("GET", "/file_comments/files/docs/a.txt")
    assert_equal([ [ 1, "first" ], [ 3, "second" ] ], listed.json.map { |comment| comment.values_at("id", "body") })
    refute listed.body.include?("docs/a.txt")
    reaction = api("POST", "/file_comment_reactions", { "file_comment_id" => 404, "emoji" => "+1" })
    assert_equal [ 201, { "id" => 1, "emoji" => "+1" } ], [ reaction.status, reaction.json ]
  end

  # Behaviors by path: the path itself, and with ancestor_behaviors the folders above it.
  def test_behaviors_list_by_path_and_ancestors
    [ "", "a", "a/b", "c" ].each { |path| api("POST", "/behaviors", { "path" => path, "behavior" => "webhook", "value" => { "url" => "https://example.com" } }) }
    assert_equal([ "a/b" ], api("GET", "/behaviors/folders/a/b").json.map { |behavior| behavior["path"] })
    assert_equal([ "", "a", "a/b" ], api("GET", "/behaviors/folders/a/b", { "ancestor_behaviors" => true }).json.map { |behavior| behavior["path"] })
    assert_equal 501, api("GET", "/behaviors/folders/a/b", { "sort_by" => { "path" => "asc" } }).status
  end

  def test_history_lists_scope_by_file_folder_user_and_logins
    actions = [ { "path" => "x.txt", "action" => "create", "user_id" => 1 }, { "path" => "dir", "action" => "create", "user_id" => 2 },
                { "action" => "login", "user_id" => 1 }, { "action" => "failedlogin", "user_id" => 2 }, { "path" => "x.txt", "action" => "read", "user_id" => 2 } ]
    reset({ "history" => actions })
    ids = ->(path, params = nil) { api("GET", path, params).json.map { |action| action["id"] } }
    assert_equal [ 1, 5 ], ids.call("/history/files/x.txt")
    assert_equal [ 2 ], ids.call("/history/folders/dir")
    assert_equal [ 2, 4, 5 ], ids.call("/history/users/2")
    assert_equal [ 3, 4 ], ids.call("/history/login")
    assert_equal [ 5 ], ids.call("/history/files/x.txt", { "per_page" => 1, "cursor" => api("GET", "/history/files/x.txt", { "per_page" => 1 }).headers["x-files-cursor"] })
    assert_equal 501, api("GET", "/history/login", { "start_at" => "2030-01-01T00:00:00Z" }).status
  end

  # Which categories apply to a path is decided by folder behaviors the simulator does not
  # evaluate, so fixtures assign it with _scope.
  def test_fixture_scopes_assign_categories_to_paths
    reset({ "metadata_categories" => [ { "name" => "legal", "_scope" => { "path" => "contracts" } }, { "name" => "other" } ] })
    assert_equal([ "legal" ], api("GET", "/metadata_categories/list_by_path/contracts").json.map { |category| category["name"] })
    invalid = control("POST", "reset", { "fixtures" => { "groups" => [ { "name" => "g", "_scope" => { "path" => "x" } } ] } })
    assert_equal [ 422, "fixtures.groups[0]: _scope may set only nothing for this resource; got path" ], [ invalid.status, invalid.json["error"] ]
  end

  def test_requests_list_by_folder_and_a_delete_only_resource_uses_fixtures
    api("POST", "/requests", { "path" => "in", "destination" => "a.txt" })
    api("POST", "/requests", { "path" => "out", "destination" => "b.txt" })
    assert_equal([ "a.txt" ], api("GET", "/requests/folders/in").json.map { |request| request["destination"] })
    assert_equal 501, api("GET", "/requests/folders/in", { "mine" => true }).status
    reset({ "partner_sites" => [ {}, {} ] })
    assert_equal [ 204, 404, 204 ], [ api("DELETE", "/partner_sites/1").status, api("DELETE", "/partner_sites/1").status, api("DELETE", "/partner_sites/2").status ]
  end

  # Styles are keyed by path: the first change creates one, and its file is an attachment.
  def test_path_records_are_found_changed_and_deleted_by_path
    assert_equal 404, api("GET", "/styles/brand").status
    logo = { "encoded_content" => [ "PNG\x00bytes".b ].pack("m0"), "filename" => "logo 100%.png", "type" => "image/png" }
    created = api("PATCH", "/styles/brand", { "logo_click_href" => "https://example.com", "file" => logo })
    assert_equal [ 200, { "id" => 1, "path" => "brand", "logo_click_href" => "https://example.com" } ], [ created.status, created.json ]
    assert_equal({ "param" => "file", "filename" => "logo 100%.png", "raw_filename" => "logo 100%.png", "content_type" => "image/png", "size" => 9,
                   "sha256" => Digest::SHA256.hexdigest("PNG\x00bytes".b), "encoding" => "encoded_content" }, journal.last["attachments"].first
    )
    assert_equal({ "id" => 1, "path" => "brand", "logo_click_href" => "https://other.example.com" }, api("PATCH", "/styles/brand", { "logo_click_href" => "https://other.example.com" }).json)
    assert_equal [ 204, 404 ], [ api("DELETE", "/styles/brand").status, api("GET", "/styles/brand").status ]
    assert_equal 501, api("GET", "/styles/a//b").status
  end

  # Configuration-dependent answers come only from fixtures, checked against their entities.
  def test_fixture_responses_answer_only_what_a_fixture_supplies
    assert_equal([ 501, "simulation/not-supported" ], api("GET", "/site/usage").then { |response| [ response.status, response.json["type"] ] })
    loaded = reset({ "responses" => { "site.get_usage" => { "id" => 9_223_372_036_854_775_807, "current_storage" => 5, "high_water_user_count" => 3 },
                                      "remote_servers.find_configuration_file" => { "7" => { "id" => 7, "permission_set" => "full" } },
                                      "holiday_regions.get_supported" => [ { "code" => "us", "name" => "United States" }, { "code" => "ca", "name" => "Canada" } ] } }
                  )
    assert_equal({ "site.get_usage" => 1, "remote_servers.find_configuration_file" => 1, "holiday_regions.get_supported" => 1 }, loaded["responses"])
    assert_equal({ "id" => 9_223_372_036_854_775_807, "current_storage" => 5, "high_water_user_count" => 3 }, api("GET", "/site/usage").json, "a supplied id is answer data")
    assert_equal [ 200, 404 ], [ api("GET", "/remote_servers/7/configuration_file").status, api("GET", "/remote_servers/8/configuration_file").status ]
    assert_equal 7, api("GET", "/remote_servers/7/configuration_file", { "id" => 8 }).json["id"], "the route names the answer, not a query copy of its key"
    first = api("GET", "/holiday_regions/supported", { "per_page" => 1 })
    second = api("GET", "/holiday_regions/supported", { "per_page" => 1, "cursor" => first.headers["x-files-cursor"] })
    assert_equal [ [ "us" ], [ "ca" ], nil ], [ first.json.map { |region| region["code"] }, second.json.map { |region| region["code"] }, second.headers["x-files-cursor"] ]
    invalid = control("POST", "reset", { "fixtures" => { "responses" => { "site.get_usage" => { "current_storage" => "lots", "id" => 2**63 } } } })
    assert_equal [ 422, "fixtures.responses.site.get_usage: id is invalid, current_storage is invalid" ], [ invalid.status, invalid.json["error"] ]
    unknown = control("POST", "reset", { "fixtures" => { "responses" => { "site.get_usage" => { "made_up" => 1 } } } })
    assert_equal 422, unknown.status
  end

  # A lookup fixture lists the synthetic keys that exist: one of them gets 204 with no body, any other
  # 404, and without a fixture the lookup gets 501. Nothing of real partner pairing is simulated. The
  # key left out fails the parameter validation first, fixture or not; sent null (a bare
  # ?pairing_key) or empty it passes, and names none of the listed keys, which are non-empty strings.
  def test_a_lookup_answers_only_whether_a_fixture_key_exists
    lookup = ->(query) { request(app, "GET", "/api/rest/v1/partner_site_requests/find_by_pairing_key#{query}") }
    outcome = ->(response) { [ response.status, response.json["type"], response.headers["x-files-error-class"] ] }
    assert_equal [ 501, "simulation/not-supported", "simulation/not-supported" ], outcome.call(lookup.call("?pairing_key=k1"))
    assert_equal [ [ 501 ] * 2, [ 422, "bad-request", "bad-request" ] ], [ [ lookup.call("?pairing_key").status, lookup.call("?pairing_key=").status ], outcome.call(lookup.call("")) ]
    assert_equal({ "partner_site_requests.find_by_pairing_key" => 2 }, reset({ "responses" => { "partner_site_requests.find_by_pairing_key" => %w[k1 k2] } })["responses"])
    assert_equal([ 204, "" ], lookup.call("?pairing_key=k1").then { |response| [ response.status, response.body ] })
    [ "?pairing_key=k3", "?pairing_key", "?pairing_key=" ].each { |query| assert_equal [ 404, "not-found", "not-found" ], outcome.call(lookup.call(query)), query }
    omitted = lookup.call("")
    assert_equal [ 422, "bad-request", "pairing_key is missing", "bad-request" ], [ omitted.status, omitted.json["type"], omitted.json["error"], omitted.headers["x-files-error-class"] ]
    assert_equal 422, control("POST", "reset", { "fixtures" => { "responses" => { "partner_site_requests.find_by_pairing_key" => { "k1" => {} } } } }).status
    assert_equal 422, control("POST", "reset", { "fixtures" => { "responses" => { "partner_site_requests.find_by_pairing_key" => [ "" ] } } }).status, "a listed key is a non-empty string"
  end

  # A run's node is answered by the run in the route and the node_id: left out, node_id fails the
  # parameter validation before the fixture or an option the simulator does not model is considered;
  # sent empty it is part of the key, so "3/" answers it; sent null it names no key, "3/" included.
  # A query copy of the run's id never replaces the route's.
  def test_a_node_id_left_out_sent_null_or_sent_empty_stays_distinct
    node = ->(run, query, to: app) { request(to, "GET", "/api/rest/v1/automation_runs/#{run}/node#{query}") }
    assert_equal [ [ 422, "bad-request", "node_id is missing" ], 501, 501 ], [ node.call(3, "").json.values_at("http-code", "type", "error"), node.call(3, "?node_id=").status, node.call(3, "?node_id").status ]
    reset({ "responses" => { "automation_runs.find_node" => { "3/" => { "node_id" => "" }, "3/n1" => { "node_id" => "n1" } } } })
    assert_equal([ 200, { "node_id" => "" } ], node.call(3, "?node_id=").then { |found| [ found.status, found.json ] })
    assert_equal([ 200, { "node_id" => "n1" } ], node.call(3, "?id=4&node_id=n1").then { |found| [ found.status, found.json ] })
    assert_equal [ 404, 404, 404, 404 ], [ node.call(3, "?node_id").status, request(app, "GET", "/api/rest/v1/automation_runs/3/node", '{"node_id": null}').status, node.call(3, "?node_id=n2").status, node.call(4, "?node_id=n1&id=3").status ]
    assert_equal([ 422, "bad-request" ], node.call(3, "").then { |omitted| [ omitted.status, omitted.headers["x-files-error-class"] ] })

    schema = JSON.parse(File.read(FilesMockServer::Simulation::SCHEMA_PATH))
    schema["fixture_responses"]["automation_runs.find_node"]["params"]["include_steps"] = { "type" => "boolean", "required" => false }
    Tempfile.create([ "schema", ".json" ]) do |file|
      file.write(JSON.generate(schema))
      file.flush
      optioned = Rack::Lint.new(FilesMockServer::Simulation::App.new(schema_path: file.path, transfer_origin: SimulationRequests::ORIGIN))
      assert_equal [ 422, "bad-request" ], node.call(3, "?include_steps=true", to: optioned).json.values_at("http-code", "type")
      assert_equal [ 501, "simulation/not-supported" ], node.call(3, "?node_id=n1&include_steps=true", to: optioned).json.values_at("http-code", "type")
    end
  end

  # PATCH /files/{path} keeps metadata with the path through a move, and a new version drops it.
  def test_file_metadata_is_changed_moved_and_dropped_with_a_new_version
    upload("docs/a.txt", [ "a" ])
    api("POST", "/folders/docs/sub", {})
    changed = api("PATCH", "/files/docs/a.txt", { "custom_metadata" => { "owner" => "legal", "rank" => "2" }, "priority_color" => "red", "provided_mtime" => "2031-01-01T00:00:00Z" })
    assert_equal [ 200, { "owner" => "legal", "rank" => "2" }, "red", "2031-01-01T00:00:00Z" ], [ changed.status, *changed.json.values_at("custom_metadata", "priority_color", "provided_mtime") ]
    folder = api("PATCH", "/files/docs/sub", { "provided_mtime" => "2032-01-01T00:00:00Z" })
    assert_equal [ "directory", "2032-01-01T00:00:00Z" ], folder.json.values_at("type", "provided_mtime")
    api("POST", "/file_actions/move/docs/a.txt", { "destination" => "docs/b.txt" })
    assert_equal "red", stat("docs/b.txt").json["priority_color"]
    upload("docs/b.txt", [ "new" ])
    refute stat("docs/b.txt").json.key?("priority_color")
    assert_equal 404, api("PATCH", "/files/missing.txt", { "priority_color" => "red" }).status

    # Merging into an existing folder keeps the destination's metadata. A copy keeps the source's;
    # a move ends it, so a new folder at the old path starts without it.
    %w[src dst].each { |name| api("POST", "/folders/#{name}", {}) }
    api("PATCH", "/files/src", { "priority_color" => "red" })
    api("PATCH", "/files/dst", { "priority_color" => "blue" })
    assert_equal 201, api("POST", "/file_actions/copy/src", { "destination" => "dst", "overwrite" => true }).status
    assert_equal(%w[red blue], %w[src dst].map { |name| stat(name).json["priority_color"] })
    assert_equal 201, api("POST", "/file_actions/move/src", { "destination" => "dst", "overwrite" => true }).status
    assert_equal [ 404, "blue" ], [ stat("src").status, stat("dst").json["priority_color"] ]
    api("POST", "/folders/src", {})
    refute stat("src").json.key?("priority_color"), "a new folder at a moved folder's path starts without its metadata"
  end

  # The API's model saves at most 32 custom_metadata keys, keys of at most 256 characters and values
  # of at most 1024 (String#length, so a multibyte character counts once). An update past any limit
  # gets one model-save error listing every failure in order (each key's, then the count), and changes
  # nothing it sent, provided_mtime and priority_color included, on a file or a folder. A missing path
  # and an invalid parameter are still answered first.
  def test_custom_metadata_limits_are_inclusive_and_a_refused_update_changes_nothing
    upload("docs/a.txt", [ "a" ])
    api("POST", "/folders/docs/sub", {})
    keys = ->(count) { (1..count).to_h { |number| [ "key#{number}", "value#{number}" ] } }
    {
      "32 keys" => keys.call(32),
      "256-character keys" => { "k" * 256 => "v", "日" * 256 => "v" },
      "1024-character values" => { "ascii" => "v" * 1024, "emoji" => "😀" * 1024 },
    }.each do |name, metadata|
      %w[docs/a.txt docs/sub].each do |path|
        kept = api("PATCH", "/files/#{path}", { "custom_metadata" => metadata, "priority_color" => "red", "provided_mtime" => "2031-01-01T00:00:00Z" })
        assert_equal [ 200, metadata, "red", "2031-01-01T00:00:00Z" ], [ kept.status, *kept.json.values_at("custom_metadata", "priority_color", "provided_mtime") ], "#{name} on #{path}"
      end
    end

    refusal = lambda do |*failures|
      messages = { "key_too_long" => "Custom metadata key is too long", "value_too_long" => "Custom metadata value is too long",
                   "too_many_keys" => "Custom metadata has too many keys" }.values_at(*failures)
      { "error" => messages.join(", "), "http-code" => 422, "model_errors" => { "custom_metadata" => messages }, "model_error_keys" => { "custom_metadata" => failures },
        "errors" => messages, "title" => "Model Save Error", "type" => "processing-failure/model-save-error" }
    end
    long = keys.call(31).merge("k" * 257 => "v" * 1025, "plain" => "日" * 1025)
    {
      "33 keys" => [ keys.call(33), refusal.call("too_many_keys") ],
      "a 257-character key" => [ { "k" * 257 => "v" }, refusal.call("key_too_long") ],
      "a 257-character Unicode key" => [ { "日" * 257 => "v" }, refusal.call("key_too_long") ],
      "a 1025-character value" => [ { "ascii" => "v" * 1025 }, refusal.call("value_too_long") ],
      "a 1025-character Unicode value" => [ { "emoji" => "😀" * 1025 }, refusal.call("value_too_long") ],
      "every limit at once" => [ long, refusal.call("key_too_long", "value_too_long", "value_too_long", "too_many_keys") ],
    }.each do |name, (metadata, body)|
      %w[docs/a.txt docs/sub].each do |path|
        before = stat(path).json
        refused = api("PATCH", "/files/#{path}", { "custom_metadata" => metadata, "priority_color" => "blue", "provided_mtime" => "2033-01-01T00:00:00Z" })
        assert_equal [ 422, "processing-failure/model-save-error", body ], [ refused.status, refused.headers["x-files-error-class"], refused.json ], "#{name} on #{path}"
        assert_equal before, stat(path).json, "#{name}: #{path} keeps what it had"
      end
    end

    assert_equal 404, api("PATCH", "/files/missing.txt", { "custom_metadata" => keys.call(33) }).status
    invalid = api("PATCH", "/files/docs/a.txt", { "custom_metadata" => keys.call(33), "provided_mtime" => "not a time" })
    assert_equal [ 422, "bad-request", "provided_mtime is invalid" ], [ invalid.status, *invalid.json.values_at("type", "error") ]
    replaced = api("PATCH", "/files/docs/a.txt", { "custom_metadata" => { "owner" => "legal" } })
    assert_equal [ 200, { "owner" => "legal" }, "red" ], [ replaced.status, *replaced.json.values_at("custom_metadata", "priority_color") ]
  end

  # custom_metadata values are strings or null, as the API's parameter coercion admits them: a
  # number, a boolean, an object or an array is refused as an invalid parameter (before the path is
  # looked up, so even for a missing one), never converted to text, and the update changes nothing. A
  # form body's "false" is a string. Empty strings and null values are kept, an empty object replaces
  # the metadata, and a null custom_metadata clears it to {}.
  def test_custom_metadata_values_are_strings_or_null
    upload("docs/a.txt", [ "a" ])
    assert_equal 200, api("PATCH", "/files/docs/a.txt", { "custom_metadata" => { "owner" => "legal" }, "priority_color" => "red" }).status
    before = stat("docs/a.txt").json
    [ 2, 2.5, true, false, { "nested" => "x" }, [ "x" ] ].each do |value|
      %w[docs/a.txt missing.txt].each do |path|
        refused = api("PATCH", "/files/#{path}", { "custom_metadata" => { "owner" => "legal", "bad" => value }, "priority_color" => "blue" })
        assert_equal [ 422, "bad-request", "custom_metadata is invalid" ], [ refused.status, *refused.json.values_at("type", "error") ], "#{value.inspect} at #{path}"
      end
    end
    [ "text", [ { "owner" => "legal" } ] ].each do |metadata|
      refused = api("PATCH", "/files/docs/a.txt", { "custom_metadata" => metadata })
      assert_equal [ 422, "bad-request" ], [ refused.status, refused.json["type"] ], metadata.inspect
    end
    assert_equal before, stat("docs/a.txt").json

    form = request(app, "PATCH", "/api/rest/v1/files/docs/a.txt", "custom_metadata%5Bflag%5D=false", { "CONTENT_TYPE" => "application/x-www-form-urlencoded" })
    assert_equal [ 200, { "flag" => "false" } ], [ form.status, form.json["custom_metadata"] ]
    kept = api("PATCH", "/files/docs/a.txt", { "custom_metadata" => { "empty" => "", "unset" => nil } })
    assert_equal [ 200, { "empty" => "", "unset" => nil } ], [ kept.status, kept.json["custom_metadata"] ]
    assert_equal({ "empty" => "", "unset" => nil }, stat("docs/a.txt").json["custom_metadata"])
    assert_equal({}, api("PATCH", "/files/docs/a.txt", { "custom_metadata" => {} }).json["custom_metadata"])
    api("PATCH", "/files/docs/a.txt", { "custom_metadata" => { "owner" => "legal" } })
    cleared = api("PATCH", "/files/docs/a.txt", { "custom_metadata" => nil })
    assert_equal [ 200, {}, "red" ], [ cleared.status, *cleared.json.values_at("custom_metadata", "priority_color") ]
  end

  # A file parameter arrives as a JSON file object or a multipart part in the same request as its
  # typed companions; the journal reports its literal filename and digest, never its bytes.
  def test_attachments_are_checked_reported_and_never_stored
    avatar = { "encoded_content" => [ "\x89PNG\x00".b ].pack("m0"), "filename" => "a%2Fb\\c.png", "type" => "image/png" }
    created = api("POST", "/users", { "username" => "u", "avatar_file" => avatar, "require_password_change" => false, "notes" => nil })
    assert_equal [ 201, { "id" => 1, "username" => "u", "require_password_change" => false, "notes" => nil } ], [ created.status, created.json ]
    assert_equal [ "a%2Fb\\c.png", "a%2Fb\\c.png", 5, "encoded_content" ], journal.last["attachments"].first.values_at("filename", "raw_filename", "size", "encoding")
    refute_includes control("GET", "journal").body, avatar["encoded_content"]
    assert_equal([ 422, "avatar_file is invalid" ], api("POST", "/users", { "username" => "v", "avatar_file" => { "encoded_content" => "!!" } }).then { |response| [ response.status, response.json["error"] ] })

    boundary = "gollum-boundary"
    body = [ "--#{boundary}", %(Content-Disposition: form-data; name="path"), "", "in",
             "--#{boundary}", %(Content-Disposition: form-data; name="behavior"), "", "webhook",
             "--#{boundary}", %(Content-Disposition: form-data; name="value[url]"), "", "https://example.com",
             "--#{boundary}", %(Content-Disposition: form-data; name="attachment_file"; filename="x%25y.txt"), "Content-Type: text/plain", "", "hello",
             "--#{boundary}--", "" ].join("\r\n")
    multipart = request(app, "POST", "/api/rest/v1/behaviors", body, { "CONTENT_TYPE" => "multipart/form-data; boundary=#{boundary}" })
    assert_equal [ 201, "in", { "url" => "https://example.com" } ], [ multipart.status, *multipart.json.values_at("path", "value") ]
    attachment = journal.last["attachments"].first
    assert_equal [ "attachment_file", "x%25y.txt", 5, Digest::SHA256.hexdigest("hello"), "multipart" ], attachment.values_at("param", "raw_filename", "size", "sha256", "encoding")
    assert_equal({ "path" => "string", "behavior" => "string", "value" => "object", "attachment_file" => "file" }, journal.last["wire"])
  end

  # Destination helpers name another store; the journal records the scope, nothing else changes.
  def test_external_destinations_are_journaled_with_their_scope
    upload("_/RemoteServers/7/in/x.bin", [ "x" ])
    api("POST", "/file_actions/copy/_/RemoteServers/7/in/x.bin", { "destination" => "_/Sites/3/y.bin" })
    scopes = journal.filter_map { |entry| entry["destination_scope"]&.merge("operation" => entry["operation"]) }
    assert_includes scopes, { "kind" => "remote_server", "id" => 7, "operation" => "files.begin_upload" }
    assert_includes scopes, { "kind" => "child_site", "id" => 3, "operation" => "files.copy" }
    assert_equal "x", download("_/Sites/3/y.bin").body
  end

  # Cursors with special characters must come back exactly; one decoded or re-encoded is refused.
  def test_special_character_cursors_must_be_sent_back_exactly
    assert_equal 200, control("POST", "reset", { "profile" => { "list_cursors" => "special-characters" }, "fixtures" => { "groups" => [ { "name" => "a" }, { "name" => "b" } ] } }).status
    cursor = api("GET", "/groups", { "per_page" => 1 }).headers["x-files-cursor"]
    assert cursor.start_with?("2:a+b &x=y%25#"), cursor
    assert_equal([ "b" ], request(app, "GET", "/api/rest/v1/groups?per_page=1&cursor=#{ERB::Util.url_encode(cursor)}").json.map { |group| group["name"] })
    mangled = request(app, "GET", "/api/rest/v1/groups?per_page=1&cursor=#{cursor.tr(" ", "+")}")
    assert_equal [ 422, "bad-request/invalid-cursor" ], [ mangled.status, mangled.json["type"] ]
    upload("d/a", [ "a" ])
    upload("d/b", [ "b" ])
    folder_cursor = api("GET", "/folders/d", { "per_page" => 1 }).headers["x-files-cursor"]
    assert_equal [ [ "d/b" ] ], [ api("GET", "/folders/d", { "per_page" => 1, "cursor" => folder_cursor }).json.map { |entry| entry["path"] } ]
  end

  # Cursors travel in headers and stay ASCII; a query scalar can hold Unicode too. A fixture response
  # keyed by the scalar answers only when the server decodes exactly the value the fixture names.
  def test_a_special_character_query_scalar_must_arrive_exactly
    scalar = "a+b &x=y%25#\u00e9"
    reset({ "responses" => { "automation_runs.find_node" => { "3/#{scalar}" => { "node_id" => scalar } } } })
    found = request(app, "GET", "/api/rest/v1/automation_runs/3/node?node_id=#{ERB::Util.url_encode(scalar)}")
    assert_equal [ 200, { "node_id" => scalar } ], [ found.status, found.json ]
    assert_equal 404, request(app, "GET", "/api/rest/v1/automation_runs/3/node?node_id=#{ERB::Util.url_encode(ERB::Util.url_encode(scalar))}").status
    assert_equal 404, request(app, "GET", "/api/rest/v1/automation_runs/3/node?node_id=#{ERB::Util.url_encode(scalar).sub("%2B", "+")}").status, "a + left unencoded arrives as a space"
  end

  private

  def stat(path)
    api("GET", "/files/#{route(path)}", { "action" => "stat" })
  end
end
