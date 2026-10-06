require_relative "test_helper"

# Record resources: every regular CRUDL resource in the Swagger document the server was generated
# from, held as records (lib/simulation/records.rb).
class RecordsTest < Minitest::Test
  include SimulationRequests
  include FileRequests

  SCHEMA = JSON.parse(File.read(FilesMockServer::Simulation::SCHEMA_PATH))

  def setup
    @app = new_app
  end

  # A value each schema rule accepts, chosen independently of the simulator's own converters.
  def sample(rule)
    return rule["enum"].first if rule["enum"]

    case rule["type"]
    when "string" then rule["format"] == "date-time" ? "2030-01-02T03:04:05Z" : "sample"
    when "date-time" then "2030-01-02T03:04:05Z"
    when "date" then "2030-01-02"
    when "boolean" then true
    when "int64" then 7
    when "double" then 1.5
    when "decimal" then "12.50"
    when "array(string)" then [ "a", "b" ]
    when "array(int64)" then [ 3, 4 ]
    when "array(decimal)" then [ "1.5" ]
    when "array(object)" then [ { "k" => "v" } ]
    when "object" then { "k" => "v" }
    end
  end

  def required_params(operation)
    operation["params"].select { |name, rule| rule["required"] && name != "id" }.transform_values { |rule| sample(rule) }
  end

  # Every resource either keeps what it was given through its whole lifecycle, or refuses what it
  # does not simulate with a 501 naming it; nothing is accepted and silently dropped. An id the schema
  # types as a string comes from the fixture, and a list that requires its parent is asked for it.
  def test_every_record_resource_keeps_its_records_through_their_lifecycle_or_refuses_visibly
    outcomes = SCHEMA["resources"].to_h do |name, resource|
      operations = resource["operations"]
      string_id = resource.dig("properties", "id", "type") == "string"
      parents = operations["list"] ? required_params(operations["list"]) : {}
      created = if operations["create"]
                  params = required_params(operations["create"])
                  response = api("POST", resource["path"], params)
                  next [ name, "create refused: #{response.json["error"]}" ] if response.status == 501

                  assert_equal operations["create"]["status"], response.status, "#{name}: #{response.body}"
                  params.each do |field, value|
                    next unless resource["properties"].key?(field)

                    assert_equal value, response.json[field], "#{name}.#{field}"
                  end
                  response.json
                else
                  fixture = resource["properties"].except("id").select { |_, rule| sample(rule) }.first(2).to_h.transform_values { |rule| sample(rule) }
                  fixture["id"] = "sample" if string_id
                  parents.each { |param, value| resource["properties"].key?(param) ? fixture[param] = value : (fixture["_scope"] ||= {})[param] = value }
                  reset({ name => [ fixture ] })
                  # A resource with only a delete is filled by fixtures and deleted once.
                  next [ name, 2.times.map { api("DELETE", "#{resource["path"]}/1").status } == [ 204, 404 ] ? "kept" : "delete failed" ] if operations.keys == [ "delete" ]

                  operations["list"] ? api("GET", resource["path"], parents).json.first : api("GET", "#{resource["path"]}/1").json
                end
      next [ name, "listed" ] unless resource["key"]

      id = string_id ? "sample" : 1
      assert_equal id, created["id"], name
      path = "#{resource["path"]}/#{id}"
      assert_equal created, api("GET", path).json, name if operations["find"]
      if operations["update"]
        field, rule = operations["update"]["params"].find { |candidate, candidate_rule| resource["properties"].key?(candidate) && candidate != "id" && sample(candidate_rule) }
        if field
          updated = api("PATCH", path, { field => sample(rule) })
          assert_equal 200, updated.status, "#{name}: #{updated.body}"
          assert_equal sample(rule), updated.json[field], "#{name}.#{field}"
        end
      end
      assert_includes api("GET", resource["path"], parents).json.map { |record| record["id"] }, id, name if operations["list"]
      if operations["delete"]
        assert_equal 204, api("DELETE", path).status, name
        assert_equal 404, api("GET", path).status, name if operations["find"]
      end
      [ name, "kept" ]
    end
    refused = outcomes.reject { |_, outcome| %w[kept listed].include?(outcome) }
    refused.each_value { |outcome| assert_match(/\Acreate refused: Simulation does not support these parameters: /, outcome) }
    assert_operator outcomes.count { |_, outcome| outcome == "kept" }, :>, refused.size, outcomes.inspect
  end

  def test_values_keep_their_types_and_unset_null_false_and_zero_stay_distinct
    created = api("POST", "/schedules", { "name" => "weekdays", "schedule_days_of_week" => [ 1, 2, 3, 4, 5 ], "schedule_times_of_day" => [ "08:00" ], "holiday_region" => nil })
    assert_equal 201, created.status, created.body
    # Unset fields are left out; an explicit null is kept as null.
    assert_equal({ "id" => 1, "name" => "weekdays", "schedule_days_of_week" => [ 1, 2, 3, 4, 5 ], "schedule_times_of_day" => [ "08:00" ], "holiday_region" => nil }, created.json)

    subscription = api("POST", "/event_subscriptions", { "name" => "all", "enabled" => false, "message_only" => false, "event_channel_id" => 0, "filter" => { "path" => "a" } })
    assert_equal [ false, false, 0, { "path" => "a" } ], subscription.json.values_at("enabled", "message_only", "event_channel_id", "filter")
    # The schema declares integer parameters as int32.
    too_large = api("POST", "/event_subscriptions", { "name" => "all", "event_channel_id" => 2_147_483_648 })
    assert_equal [ 422, "event_channel_id is invalid" ], [ too_large.status, too_large.json["error"] ]
    cleared = api("PATCH", "/event_subscriptions/1", { "event_channel_id" => nil })
    assert_nil cleared.json.fetch("event_channel_id")

    wrong = api("POST", "/schedules", { "name" => "x", "schedule_days_of_week" => [ "monday" ], "schedule_times_of_day" => "08:00" })
    assert_equal [ 422, "schedule_days_of_week is invalid, schedule_times_of_day is invalid" ], [ wrong.status, wrong.json["error"] ]
    assert_equal([ 1 ], api("GET", "/schedules").json.map { |schedule| schedule["id"] })
    # The journal records each value's JSON type, never the value.
    entry = journal.find { |candidate| candidate["operation"] == "event_subscriptions.create" }
    assert_equal({ "name" => "string", "enabled" => "boolean", "message_only" => "boolean", "event_channel_id" => "number", "filter" => "object" }, entry["wire"])

    # Ordinary JSON fractions inside an object stay JSON numbers at any depth; only schema decimals
    # become exact strings.
    reset({ "site" => { "name" => "Example" } })
    watermark = api("PATCH", "/site", { "bundle_watermark_value" => { "fraction" => 0.5, "nested" => [ { "fraction" => 1.25 } ], "integer" => 3, "bool" => false, "none" => nil } })
    assert_equal 200, watermark.status, watermark.body
    assert_equal({ "fraction" => 0.5, "nested" => [ { "fraction" => 1.25 } ], "integer" => 3, "bool" => false, "none" => nil }, watermark.json["bundle_watermark_value"])
    assert_includes api("GET", "/site").body, %("fraction":0.5,"nested":[{"fraction":1.25}])
    # A tiny exponent never becomes a huge string: past Coercion::MAX_ZERO_PADDING zeros a number
    # keeps its exact value in exponent form, which is still a JSON number.
    exponents = request(app, "PATCH", "/api/rest/v1/site", '{"bundle_watermark_value": {"big": 1e100000, "small": [-1e-100000], "plain": 1e32}}')
    assert_equal 200, exponents.status, exponents.body
    assert_operator exponents.body.bytesize, :<, 1_000
    assert_includes exponents.body, %("big":0.1e100001,"small":[-0.1e-99999],"plain":1#{"0" * 32})

    # An int64 field beyond a double's exact range survives the round trip (from a fixture, since
    # no parameter declares int64).
    reset({ "action_logs" => [ { "user_id" => 9_007_199_254_740_993 } ] })
    assert_includes api("GET", "/action_logs").body, %("user_id":9007199254740993)
  end

  # A request's string for an array is read as the API's parameter coercion reads it. Empty, an array
  # of strings or integers, or of objects declared [Hash] such as an automation's import_urls, is an
  # empty array; form field sets' form_fields is declared [JSON], whose blank string is no value, so
  # it arrives as an explicit null does. Other strings and members of the wrong type stay invalid,
  # nested numbers keep their exact value, and a fixture's values are checked as given.
  def test_a_string_for_an_array_is_read_as_the_api_declares_that_array
    created = api("POST", "/automations", { "automation" => "create_folder", "import_urls" => "", "trigger_actions" => "", "schedule_days_of_week" => "" })
    assert_equal [ 201, [], [], [] ], [ created.status, *created.json.values_at("import_urls", "trigger_actions", "schedule_days_of_week") ]
    automation = "/api/rest/v1/automations/#{created.json["id"]}"
    assert_equal [], request(app, "GET", automation).json["import_urls"]
    feed = request(app, "PATCH", automation, '{"import_urls": [{"name": "feed", "url": "https://example.com", "headers": {"weight": 1.25}}]}')
    assert_equal 200, feed.status, feed.body
    [ "https://example.com", " ", [ "x" ], [ nil ], { "name" => "feed" } ].each do |sent|
      refused = api("PATCH", "/automations/#{created.json["id"]}", { "import_urls" => sent })
      assert_equal [ 422, "import_urls is invalid" ], [ refused.status, refused.json["error"] ], sent.inspect
    end
    assert_includes request(app, "GET", automation).body, %("import_urls":[{"name":"feed","url":"https://example.com","headers":{"weight":1.25}}])

    set = api("POST", "/form_field_sets", { "title" => "intake", "form_fields" => [ { "label" => "Name" } ] })
    assert_equal [ 201, [ { "label" => "Name" } ] ], [ set.status, set.json["form_fields"] ]
    patch = ->(params) { api("PATCH", "/form_field_sets/#{set.json["id"]}", params).json["form_fields"] }
    assert_equal [ { "label" => "Name" } ], patch.call({ "title" => "renamed" }), "left out, the field is kept"
    assert_nil patch.call({ "form_fields" => "" })
    assert_equal [], patch.call({ "form_fields" => [] })
    assert_nil patch.call({ "form_fields" => " \n" }), "a blank line is blank to JsonArray"
    assert_equal [], patch.call({ "form_fields" => [] })
    assert_nil patch.call({ "form_fields" => nil })
    assert_equal [ 422, "form_fields is invalid" ], api("PATCH", "/form_field_sets/#{set.json["id"]}", { "form_fields" => [ "Name" ] }).json.values_at("http-code", "error")

    # An encoded form_fields value is parsed as JsonArray parses it: an array of objects, or one object
    # (wrapped), is kept as the same array sent directly, numbers included; "[]" and "null" are what they
    # encode. A malformed document, a scalar or a member that is not an object is invalid, changing
    # nothing, which is not the malformed request body's own error; an object sent directly, and an
    # encoded [Hash] array, are not parsed.
    direct = patch.call({ "form_fields" => [ { "label" => "Name", "field_type" => "text", "weight" => 1.25 } ] })
    assert_equal [ direct, direct ], [ patch.call({ "form_fields" => '[{"label": "Name", "field_type": "text", "weight": 1.25}]' }), patch.call({ "form_fields" => '{"label": "Name", "field_type": "text", "weight": 1.25}' }) ]
    form_field_set = "/api/rest/v1/form_field_sets/#{set.json["id"]}"
    assert_includes request(app, "GET", form_field_set).body, %("form_fields":[{"label":"Name","field_type":"text","weight":1.25}])
    assert_equal [ [], nil ], [ patch.call({ "form_fields" => "[]" }), patch.call({ "form_fields" => "null" }) ]
    encoded = api("POST", "/form_field_sets", { "title" => "encoded", "form_fields" => '{"label": "Email"}' })
    assert_equal [ 201, [ { "label" => "Email" } ] ], [ encoded.status, encoded.json["form_fields"] ]
    held = request(app, "GET", form_field_set).body
    [ "[1]", "[null]", "false", "123", '"[]"', "[{", '{"label": }', { "label" => "Name" } ].each do |sent|
      refused = api("PATCH", "/form_field_sets/#{set.json["id"]}", { "form_fields" => sent })
      assert_equal [ 422, "bad-request", "form_fields is invalid", "bad-request" ], [ refused.status, refused.json["type"], refused.json["error"], refused.headers["x-files-error-class"] ], sent.inspect
    end
    assert_equal held, request(app, "GET", form_field_set).body
    outer = request(app, "PATCH", form_field_set, '{"form_fields": [}')
    assert_equal [ 422, "bad-request/invalid-body" ], [ outer.status, outer.json["type"] ]
    assert_equal [ 422, "import_urls is invalid" ], api("PATCH", "/automations/#{created.json["id"]}", { "import_urls" => '[{"name": "feed"}]' }).json.values_at("http-code", "error")

    # The site's own fixture is checked as given; a request reads the same empty string as an empty array.
    unread = control("POST", "reset", { "fixtures" => { "site" => { "name" => "Example", "additional_text_file_types" => "" } } })
    assert_equal 422, unread.status, unread.body
    assert_includes unread.json["error"], "additional_text_file_types is invalid"
    reset({ "site" => { "name" => "Example" } })
    assert_equal([ 200, [] ], api("PATCH", "/site", { "additional_text_file_types" => "" }).then { |site| [ site.status, site.json["additional_text_file_types"] ] })
  end

  # A share group's create requires name and members, and Grape's presence check admits any parameter
  # that is there, null included: a name sent null does not hide that members is invalid, and what is
  # left out is missing, in declaration order (the framework's 422 bad-request). Once the parameters are
  # admitted, the ShareGroup model's own validations decide: a null or blank name, and null or empty
  # members, fail its save with the model-save error and its model-error envelope, and nothing is kept.
  # Elsewhere a required parameter sent null is still refused as missing.
  def test_a_share_group_create_separates_parameter_validation_from_the_model_save
    create = ->(body) { request(app, "POST", "/api/rest/v1/share_groups", body) }
    framework = ->(response) { [ response.status, response.json["type"], response.json["error"], response.headers["x-files-error-class"] ] }
    member = '[{"name": "Ann", "email": "ann@example.com"}]'
    assert_equal [ 422, "bad-request", "members is invalid", "bad-request" ], framework.call(create.call('{"name": null, "members": "not-an-array"}'))
    assert_equal [ 422, "bad-request", "name is missing, members is invalid", "bad-request" ], framework.call(create.call('{"members": "not-an-array"}'))
    assert_equal [ 422, "bad-request", "name is missing, members is missing", "bad-request" ], framework.call(create.call("{}"))
    assert_equal [ 422, "bad-request", "name is missing", "bad-request" ], framework.call(create.call(%({"members": #{member}})))

    members_null = create.call('{"name": "Team", "members": null}')
    assert_equal [ 422, "processing-failure/model-save-error" ], [ members_null.status, members_null.headers["x-files-error-class"] ]
    assert_equal({ "error" => "Members array cannot be empty", "http-code" => 422, "model_errors" => { "members" => [ "Members array cannot be empty" ] },
                   "model_error_keys" => { "members" => [ "members_cannot_be_empty" ] }, "errors" => [ "Members array cannot be empty" ], "title" => "Model Save Error",
                   "type" => "processing-failure/model-save-error" }, members_null.json
    )
    name_null = create.call(%({"name": null, "members": #{member}}))
    assert_equal [ 422, { "name" => [ "Name can't be blank" ] }, { "name" => [ "blank" ] } ], [ name_null.status, *name_null.json.values_at("model_errors", "model_error_keys") ]
    both = create.call('{"name": null, "members": null}')
    assert_equal [ "Name can't be blank, Members array cannot be empty", { "name" => [ "blank" ], "members" => [ "members_cannot_be_empty" ] } ], both.json.values_at("error", "model_error_keys")
    [ %({"name": " ", "members": #{member}}), '{"name": "Team", "members": []}', '{"name": "Team", "members": [{}]}' ].each do |body|
      assert_equal [ 422, "processing-failure/model-save-error" ], create.call(body).json.values_at("http-code", "type"), body
    end
    assert_equal [], api("GET", "/share_groups").json

    kept = create.call(%({"name": "Team", "members": #{member}}))
    assert_equal [ 201, 1, "Team" ], [ kept.status, *kept.json.values_at("id", "name") ]
    assert_equal [ 422, "bad-request", "username is missing", "bad-request" ], framework.call(request(app, "POST", "/api/rest/v1/users", '{"username": null}'))
  end

  # Decimals stay exact strings, whether sent as strings or as JSON numbers. The resource is added to
  # schema.json here, since the pinned production schema declares no decimal parameter and the
  # combined adaptive schema declares them only on remote mount backends.
  DECIMAL = { "type" => "decimal", "format" => "decimal" }.freeze
  QUOTES = { "path" => "/quotes", "key" => "id", "properties" => { "id" => { "type" => "int64" }, "amount" => DECIMAL },
             "operations" => { "create" => { "operation_id" => "PostQuotes", "method" => "POST", "status" => 201, "params" => { "amount" => DECIMAL.merge("required" => true) } } } }.freeze
  # The decimal-compat fixture's Foo (spec/fixtures/swagger_decimal_compat_new.json) as the generator
  # describes it: no id, a create answering 200, and a list declared to answer one entity.
  FOO_PARAMS = { "amount" => DECIMAL, "amounts" => { "type" => "array(decimal)" }, "decimal_string" => { "type" => "string", "format" => "decimal" }, "ratio" => { "type" => "double" } }.freeze
  FOOS = { "path" => "/foos", "key" => nil, "scope" => [], "properties" => FOO_PARAMS.merge("ratio" => { "type" => "double", "format" => "double" }, "decimal_string" => { "type" => "string" }, "bar" => { "type" => "Bar" }),
           "operations" => { "list" => { "operation_id" => "ListFoos", "method" => "GET", "status" => 200, "params" => FOO_PARAMS.transform_values { |rule| rule.merge("required" => false) }, "array" => false },
                             "create" => { "operation_id" => "CreateFoo", "method" => "POST", "status" => 200, "params" => FOO_PARAMS.transform_values { |rule| rule.merge("required" => nil) } } } }.freeze

  # A simulator whose schema is the generated one with `resources` added.
  def focused_app(resources)
    schema = JSON.parse(File.read(FilesMockServer::Simulation::SCHEMA_PATH))
    schema["resources"].merge!(resources)
    file = Tempfile.new([ "schema", ".json" ])
    file.write(JSON.generate(schema))
    file.close
    Rack::Lint.new(FilesMockServer::Simulation::App.new(limits: FilesMockServer::Simulation::Limits.new, schema_path: file.path, transfer_origin: ORIGIN))
  end

  def test_decimal_values_stay_exact_whether_sent_as_strings_or_numbers
    @app = focused_app("quotes" => QUOTES)
    { "12.50" => "12.50", "-0.000000000000000000001" => "-0.000000000000000000001", "123456789012345678901234567890" => "123456789012345678901234567890" }.each do |sent, kept|
      assert_equal kept, api("POST", "/quotes", { "amount" => sent }).json["amount"]
    end
    # A JSON number keeps its exact value; no binary rounding happens on the way in.
    created = request(app, "POST", "/api/rest/v1/quotes", '{"amount": 0.1000000000000000055511151231257827}')
    assert_equal [ 201, "0.1000000000000000055511151231257827" ], [ created.status, created.json["amount"] ]
    assert_equal [ %w[string number] ], [ journal.select { |entry| entry["status"] == 201 }.map { |entry| entry["wire"]["amount"] }.values_at(0, -1) ]
    # An ordinary e or E exponent is read, as the API's coercion reads it, and kept as sent, never
    # expanded or converted through a float; other spellings Float() or BigDecimal would read are not.
    %w[1e3 1E-7 1.5E+3 -1e-21 0E-7 12.50e0 1E99999999].each do |sent|
      exponent = api("POST", "/quotes", { "amount" => sent })
      assert_equal [ 201, sent ], [ exponent.status, exponent.json["amount"] ], sent
    end
    [ "12.", ".5", "NaN", "Infinity", "+1", "1_000", " 1", "1 ", "0x1A", "01", "1e", "1E+", "1e3.5", "1.5E3E2" ].each { |sent| assert_equal 422, api("POST", "/quotes", { "amount" => sent }).status, sent }
    # A JSON number's exact string may pad it with at most Coercion::MAX_ZERO_PADDING zeros: 1e32 is
    # kept whole, and past that (a 27-byte 1e100000 would once have made 100,001 bytes) it is refused
    # before its string is built, allocating no id.
    whole = request(app, "POST", "/api/rest/v1/quotes", '{"amount": 1e32}')
    assert_equal [ 201, "1#{"0" * 32}" ], [ whole.status, whole.json["amount"] ]
    [ "1e33", "1e100000", "-1e-100000" ].each do |sent|
      refused = request(app, "POST", "/api/rest/v1/quotes", %({"amount": #{sent}}))
      assert_equal [ 422, "bad-request" ], [ refused.status, refused.json["type"] ], sent
      assert_operator refused.body.bytesize, :<, 1_000, sent
    end
    assert_equal whole.json["id"] + 1, api("POST", "/quotes", { "amount" => "1" }).json["id"]
  end

  # GOL-TYPE-002: each element of a decimal array is checked and kept as a decimal is, and the
  # journal records how many elements arrived and the JSON types they arrived as (never their
  # values), since a decimal is accepted as a string or as a number and kept as the same text.
  def test_decimal_array_elements_stay_exact_and_the_journal_records_the_type_each_arrived_as
    @app = focused_app("foos" => FOOS)
    sent = [ "12345678901234567890.123456789012345678901234567890", "12.50", "-0", "0", "1E-7", "1.5E+3", "-1e-21" ]
    created = api("POST", "/foos", { "amounts" => sent, "amount" => "2.5E0" })
    assert_equal [ 200, { "amounts" => sent, "amount" => "2.5E0" } ], [ created.status, created.json ]
    numbers = request(app, "POST", "/api/rest/v1/foos", '{"amounts": [1.25, 2, 0.1000000000000000055511151231257827]}')
    assert_equal [ 200, [ "1.25", "2", "0.1000000000000000055511151231257827" ] ], [ numbers.status, numbers.json["amounts"] ]
    assert_equal [ 200, 200 ], [ request(app, "POST", "/api/rest/v1/foos", '{"amounts": ["1.25", 2]}').status, api("POST", "/foos", { "amounts" => [] }).status ]
    creates = journal.select { |entry| entry["operation"] == "foos.create" }
    elements = creates.map { |entry| entry.dig("wire_elements", "amounts") }
    assert_equal [ { "count" => 7, "types" => [ "string" ] }, { "count" => 3, "types" => [ "number" ] }, { "count" => 2, "types" => %w[number string] }, { "count" => 0, "types" => [] } ], elements
    sent_as = creates.map { |entry| entry["wire"]["amounts"] }
    assert_equal %w[array array array array], sent_as
    refute creates.first["wire_elements"].key?("amount"), "only arrays have element types"
    # A query array arrives in Rack's amounts[] form, as strings: a query carries no JSON types.
    api("GET", "/foos", { "amounts" => sent })
    assert_equal [ { "amounts" => "array" }, { "amounts" => { "count" => 7, "types" => [ "string" ] } } ], journal.last.values_at("wire", "wire_elements")
    # An empty string is an empty array to the API's coercion of an array of decimals (dry-types'
    # params array); any other string is not an array.
    assert_equal([ 200, [] ], api("POST", "/foos", { "amounts" => "" }).then { |emptied| [ emptied.status, emptied.json["amounts"] ] })
    # One element that is not a decimal refuses the whole request, which changes nothing.
    held = control("GET", "ready").json.dig("state", "records")
    [ [ "1.25", "abc" ], [ "1_000" ], [ ".5" ], [ "1e" ], [ true ], [ nil ], [ [ "1" ] ], [ { "value" => "1" } ], "1.25" ].each do |amounts|
      refused = api("POST", "/foos", { "amounts" => amounts })
      assert_equal [ 422, "amounts is invalid" ], [ refused.status, refused.json["error"] ], amounts.inspect
    end
    assert_equal held, control("GET", "ready").json.dig("state", "records")
    types = journal.last(5).map { |entry| entry.dig("wire_elements", "amounts", "types") }
    assert_equal [ %w[boolean], %w[null], %w[array], %w[object], nil ], types
    assert_equal "string", journal.last["wire"]["amounts"]
  end

  # A list declared to answer one entity (the decimal-compat fixture's ListFoos) answers the record
  # holding exactly the values its query sends, a decimal's exact text included. Finding none is
  # 404; several are not simulated. This is the simulator's reading of a synthetic schema's shape.
  def test_a_list_declared_to_answer_one_entity_finds_the_one_record_holding_exactly_its_values
    @app = focused_app("foos" => FOOS)
    first = api("POST", "/foos", { "amounts" => [ "1E-7", "12.50" ], "amount" => "3" }).json
    api("POST", "/foos", { "amounts" => [ "1E-7", "12.5" ] })
    found = api("GET", "/foos", { "amounts" => [ "1E-7", "12.50" ] })
    assert_equal [ 200, first ], [ found.status, found.json ]
    assert_equal first, api("GET", "/foos", { "amount" => "3" }).json
    # Another spelling of the same value, another order, or fewer elements find nothing.
    [ [ "1e-7", "12.50" ], [ "0.0000001", "12.50" ], [ "12.50", "1E-7" ], [ "1E-7" ] ].each do |amounts|
      missing = api("GET", "/foos", { "amounts" => amounts })
      assert_equal [ 404, "not-found" ], [ missing.status, missing.json["type"] ], amounts.inspect
    end
    ambiguous = api("GET", "/foos")
    assert_equal [ 501, "simulation/not-supported" ], [ ambiguous.status, ambiguous.json["type"] ]
    invalid = api("GET", "/foos", { "amounts" => [ "1.5", "x" ] })
    assert_equal [ 422, "amounts is invalid" ], [ invalid.status, invalid.json["error"] ]
    # The fixture's ratio (a number without a format) and decimal_string (a string with the decimal
    # format) are types the simulator does not convert, so they are refused visibly, as elsewhere.
    %w[ratio decimal_string].each do |name|
      refused = api("GET", "/foos", { name => "1" })
      assert_equal [ 501, "simulation/not-supported" ], [ refused.status, refused.json["type"] ], name
      assert_equal 501, api("POST", "/foos", { name => "1" }).status, name
    end
    # Repeated bare amounts= values are not an array: Rack keeps the last, as one string.
    bare = request(app, "GET", "/api/rest/v1/foos?amounts=1E-7&amounts=12.50")
    assert_equal [ 422, "string", nil ], [ bare.status, journal.last["wire"]["amounts"], journal.last["wire_elements"] ]
  end

  def test_filtering_sorting_and_unmodeled_parameters_are_refused_before_any_change
    reset({ "groups" => [ { "name" => "admins" } ] })
    {
      "filter" => api("GET", "/groups", { "filter" => { "name" => "admins" } }),
      "sort" => api("GET", "/groups", { "sort_by" => { "name" => "desc" } }),
      "ids" => api("GET", "/groups", { "ids" => "1" }),
      "not a field" => api("POST", "/bundles", { "paths" => [ "a" ], "create_snapshot" => true }),
      "file upload" => api("PATCH", "/behaviors/1", { "attachment_delete" => true }),
      "put" => api("PUT", "/groups/1", { "name" => "x" }),
    }.each do |name, response|
      assert_equal [ 501, "simulation/not-supported" ], [ response.status, response.json["type"] ], name
    end
    assert_equal [ { "id" => 1, "name" => "admins" } ], api("GET", "/groups").json
  end

  def test_write_only_secrets_are_checked_but_never_stored_returned_or_journaled
    secret = "never-returned-#{SecureRandom.hex(4)}"
    created = api("POST", "/siem_http_destinations", { "name" => "splunk", "destination_type" => "splunk", "splunk_token" => secret })
    assert_equal 201, created.status, created.body
    refute_includes created.body, secret
    refute_includes api("GET", "/siem_http_destinations/1").body, secret
    refute_includes control("GET", "journal").body, secret
    wrong_type = api("POST", "/siem_http_destinations", { "name" => "x", "destination_type" => "splunk", "splunk_token" => 5 })
    assert_equal [ 422, "splunk_token is invalid" ], [ wrong_type.status, wrong_type.json["error"] ]
  end

  def test_lists_without_ids_page_through_their_fixtures_in_order
    logs = (1..5).map { |number| { "path" => "file#{number}", "action" => "create" } }
    loaded = reset({ "action_logs" => logs })
    assert_equal 5, loaded["action_logs"]
    pages = []
    cursor = nil
    loop do
      response = api("GET", "/action_logs", { "per_page" => 2, "cursor" => cursor }.compact)
      pages << response.json.map { |log| log["path"] }
      cursor = response.headers["x-files-cursor"] or break
    end
    assert_equal [ %w[file1 file2], %w[file3 file4], %w[file5] ], pages
    refute(api("GET", "/action_logs").json.any? { |log| log.key?("id") })
    assert_equal [ 501, 501 ], [ api("POST", "/action_logs", {}), api("GET", "/action_logs/1") ].map(&:status)
  end

  def test_the_site_is_a_singleton_read_and_changed_with_the_update_rules
    assert_equal({}, api("GET", "/site").json)
    reset({ "site" => { "name" => "Example", "welcome_email_enabled" => true } })
    updated = api("PATCH", "/site", { "welcome_email_enabled" => false })
    assert_equal 200, updated.status, updated.body
    assert_equal({ "name" => "Example", "welcome_email_enabled" => false }, updated.json)
    invalid = api("PATCH", "/site", { "welcome_email_enabled" => "sometimes" })
    assert_equal 422, invalid.status
    assert_equal false, api("GET", "/site").json["welcome_email_enabled"]
  end

  def test_fixtures_fill_any_resource_and_refuse_what_they_cannot_check
    loaded = reset({ "users" => [ { "username" => "alice" } ], "groups" => [ { "name" => "a" }, { "name" => "b" } ], "site" => { "name" => "Example" } })
    assert_equal({ "epoch" => 1, "users" => [ 1 ], "groups" => [ 1, 2 ], "site" => true }, loaded)
    unknown = control("POST", "reset", { "fixtures" => { "widgets" => [] } })
    assert_equal [ 400, "Unknown fixtures: widgets; GET /__files_mock/v1/ready lists the resources fixtures can fill" ], [ unknown.status, unknown.json["error"] ]
    invalid = control("POST", "reset", { "fixtures" => { "groups" => [ { "name" => "a" }, { "ftp_permission" => "sometimes" } ] } })
    assert_equal [ 422, "fixtures.groups[1]: ftp_permission is invalid, name is missing" ], [ invalid.status, invalid.json["error"] ]
    # A refused reset changes nothing.
    assert_equal(%w[a b], api("GET", "/groups").json.map { |group| group["name"] })
  end

  def test_record_faults_match_the_record_id_and_fail_before_any_change
    reset({ "groups" => [ { "name" => "a" }, { "name" => "b" } ] })
    add_fault({ "operation" => "groups.update", "match" => { "id" => 2 }, "status" => 503 })
    assert_equal 200, api("PATCH", "/groups/1", { "name" => "a2" }).status
    assert_equal 503, api("PATCH", "/groups/2", { "name" => "b2" }).status
    assert_equal "b", api("GET", "/groups/2").json["name"]
    assert_equal 200, api("PATCH", "/groups/2", { "name" => "b2" }).status
  end

  # Every operation of the Swagger document is listed once, and what the inventory calls simulated
  # is exactly what the simulator serves.
  def test_the_inventory_lists_every_operation_and_matches_the_operations_served
    inventory = control("GET", "inventory").json
    entries = inventory["entries"]
    assert_equal [ inventory["operations"], inventory["operations"] ], [ entries.size, inventory["dispositions"].values.sum ]
    assert_equal entries.size, entries.map { |entry| entry["operation_id"] }.uniq.size
    listed = control("GET", "ready").json["operations"]
    assert_equal listed.size, listed.map { |operation| operation["id"] }.uniq.size, "readiness lists each operation once"
    served = listed.to_h { |operation| [ operation["id"], operation["swagger_operation_id"] ] }
    simulated = entries.select { |entry| entry["simulator_operation"] }.to_h { |entry| [ entry["simulator_operation"], entry["operation_id"] ] }
    assert_equal served.sort, simulated.sort
    assert(entries.reject { |entry| entry["simulator_operation"] }.all? { |entry| %w[gap real-only].include?(entry["disposition"]) && entry["reason"] })
    # An action is refused even when its shape looks like a record's: a webhook test sends a request.
    webhook = entries.detect { |entry| entry["operation_id"] == "PostWebhookTests" }
    assert_equal [ "gap", "real-or-provider" ], webhook.values_at("disposition", "gap_kind")
    assert_equal 501, api("POST", "/webhook_tests", { "url" => "https://example.test/hook" }).status
  end

  def test_ids_increase_per_resource_and_are_never_reused
    assert_equal([ 1, 2 ], 2.times.map { |index| api("POST", "/groups", { "name" => "g#{index}" }).json["id"] })
    assert_equal 1, api("POST", "/schedules", { "name" => "s", "schedule_days_of_week" => [ 1 ], "schedule_times_of_day" => [ "08:00" ] }).json["id"]
    api("DELETE", "/groups/2")
    assert_equal 3, api("POST", "/groups", { "name" => "g3" }).json["id"]
    # An integer id names its record by number only.
    assert_equal([ 200, 404, 404, 404 ], %w[1 0 01 one].map { |id| api("GET", "/groups/#{id}").status })
  end

  # An id the schema types as a string (a chat session's, a DNS record's, an IP address list's) is the
  # record's own data: a fixture supplies it, lists and finds return it as given, and a member route
  # finds the record holding it, decoded once, while lists still page in fixture order. These ids
  # are synthetic and name no real chat, DNS record or address.
  def test_a_string_id_is_the_records_own_data_and_names_it_in_member_routes
    sessions = [ { "id" => "session-b", "title" => "B" }, { "id" => "label 2/x", "title" => "Encoded" }, { "id" => "1", "title" => "Numeric text" },
                 { "title" => "No id" }, { "id" => nil, "title" => "Null id" } ]
    assert_equal 5, reset({ "chat_sessions" => sessions })["chat_sessions"]
    first = api("GET", "/chat_sessions", { "per_page" => 2 })
    rest = api("GET", "/chat_sessions", { "per_page" => 2, "cursor" => first.headers["x-files-cursor"] })
    assert_equal [ [ "session-b", "label 2/x" ], [ "1", nil ] ], [ first.json.map { |session| session["id"] }, rest.json.map { |session| session["id"] } ]
    assert_equal [ { "title" => "No id" }, { "id" => nil, "title" => "Null id" } ], api("GET", "/chat_sessions").json.last(2), "an unset id is left out and a null one kept"

    assert_equal({ "id" => "session-b", "title" => "B" }, api("GET", "/chat_sessions/session-b").json)
    assert_equal "Encoded", api("GET", "/chat_sessions/#{ERB::Util.url_encode("label 2/x")}").json["title"]
    assert_equal "Numeric text", api("GET", "/chat_sessions/1").json["title"], "the id \"1\", not the first record"
    %w[2 session-a label%202%252Fx null %FF].each do |id|
      missing = request(app, "GET", "/api/rest/v1/chat_sessions/#{id}")
      assert_equal [ 404, "not-found" ], [ missing.status, missing.json["type"] ], id
    end
    assert_equal [ "session-b", "1" ], journal.select { |entry| entry["operation"] == "chat_sessions.find" && entry["status"] == 200 }.map { |entry| entry["id"] }.values_at(0, 2)
    assert_equal [ "dns-1" ], reset({ "dns_records" => [ { "id" => "dns-1", "domain" => "example.test" } ] })["dns_records"]
    assert_equal [ { "id" => "dns-1", "domain" => "example.test" } ], api("GET", "/dns_records").json

    # A fixture's id is checked as a string and must not repeat one held; a refused reset changes nothing.
    duplicate = control("POST", "reset", { "fixtures" => { "chat_sessions" => [ { "id" => "a" }, { "id" => "a" } ] } })
    assert_equal [ 422, "fixtures.chat_sessions[1]: id \"a\" is already held by another chat_sessions record" ], [ duplicate.status, duplicate.json["error"] ]
    numeric = control("POST", "reset", { "fixtures" => { "chat_sessions" => [ { "id" => 5 } ] } })
    assert_equal [ 422, "fixtures.chat_sessions[0]: id is invalid" ], [ numeric.status, numeric.json["error"] ]
    assert_equal([ "dns-1" ], api("GET", "/dns_records").json.map { |record| record["id"] })
    # A fault rule's match.id is a number, so it cannot name a string id; an unmatched rule still applies.
    refused = control("POST", "faults", { "operation" => "chat_sessions.find", "match" => { "id" => 1 }, "status" => 503 })
    assert_equal [ 400, "chat_sessions.find rules cannot use match" ], [ refused.status, refused.json["error"] ]
  end
end
