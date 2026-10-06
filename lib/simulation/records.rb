module FilesMockServer
  module Simulation
    # One Files.com API resource held as records in simulator memory: list and create at its
    # collection path, find, update and delete at /{path}/{id}. Parameters are checked against the
    # Swagger metadata in schema.json, but only a closed set of types and formats is understood:
    # any other supplied parameter is rejected as not simulated instead of being accepted and ignored.
    #
    # What a record holds is exactly what was supplied: a field that was never set is left out of
    # its responses, an explicit null is kept as null, and false, zero and empty strings stay as
    # sent. Nothing derives one field from another, checks uniqueness, follows a foreign key, or
    # filters and sorts lists; those are outside the simulated contract.
    #
    # Records keyed by an integer id get increasing ids per resource that are never reused. Every
    # record also has a private increasing key that orders lists and their cursors; an integer id is
    # that key. An id the schema types as a string (a chat session's, a DNS record's) is instead the
    # record's own data, which fixtures supply and member routes find; the simulator never invents
    # one. A resource whose entity has no id keeps its records in creation order (log lists,
    # recipients), or finds them by some of their own fields ("key_fields", such as a group
    # membership's group_id and user_id). A required create or list parent key that is not a field of
    # the record ("scope", such as a comment's path or a history export result's history_export_id)
    # is kept, never returned and never checked against the parent; lists may be scoped to it (see
    # #list and #list_scoped). A required list parent key that is a field ("parent_fields", an
    # automation run's automation_id) selects the records holding it.
    class Records
      # A parameter that is not a field of the record is accepted only when it carries a secret the
      # API never returns: it is type-checked, then never stored, returned or journaled.
      WRITE_ONLY = /password|passphrase|secret|private_key|token|api_key|access_key|key_id|credentials_json|client_certificate|application_key/
      PAGINATION_PARAMS = %w[cursor per_page].freeze
      # Files.com API list page sizes.
      DEFAULT_PER_PAGE = 1_000
      MAX_PER_PAGE = 10_000
      # Where a stored record keeps its scope; a symbol can never be a field name.
      SCOPE = :scope
      # The fixture key that sets a record's scope, for scopes no create parameter carries.
      FIXTURE_SCOPE = "_scope".freeze
      # Request arrays of objects the Files.com source declares as nested objects ([JSON], read by
      # Grape's JsonArray) rather than [Hash]; Swagger does not tell them apart (see
      # Coercion.request_array). Among the resources simulated, only form field sets' form_fields is
      # (form_field_sets_controller.rb, optional_nested_objects); every other array of objects is [Hash].
      JSON_ARRAYS = { "form_field_sets" => %w[form_fields] }.freeze
      # Model validations the simulator represents, where the Files.com source traces a create to a model
      # save that can fail after the API's parameter validation admitted the request (Create#save raises
      # ApiError::ModelSaveError with the model). For these resources a required parameter sent null is
      # admitted, as Grape's presence check admits any parameter that is there, and these rules decide:
      # each is [ field, error key, full message, blank test ], in the model's validation order. Elsewhere a
      # required parameter sent null is still refused as missing, since what each model does is not simulated.
      MODEL_VALIDATIONS = {
        # ShareGroup (share_group.rb:18-20, 29-31): name presence (ActiveModel's :blank and its default
        # message), then members_not_empty (the pinned locale's "array cannot be empty", also for a single
        # blank member). Its member models and user, site and workspace context are not simulated.
        "share_groups" => [
          [ "name", "blank", "Name can't be blank", ->(name) { name.nil? || name.match?(/\A[[:space:]]*\z/) } ],
          [ "members", "members_cannot_be_empty", "Members array cannot be empty", ->(members) { members.nil? || members.empty? || (members.size == 1 && members.first.empty?) } ]
        ],
      }.freeze

      attr_reader :resource, :path, :operations

      # definition: schema.json's description of the resource: "path", "key" ("id" or null),
      # "key_fields", "scope", "parent_fields", "operations" (action => { "operation_id", "status",
      # "params" }) and "properties" (field => rule). allocated_id: whether "id" is the simulator's to
      # allocate, and so never taken from what is supplied; false where "id" is supplied data, as in a
      # fixture response, and for a string id (#public_id?).
      def initialize(resource, definition, max_records:, allocated_id: true)
        @resource = resource
        @path = definition.fetch("path")
        @keyed = definition.fetch("key", "id") == "id"
        @key_fields = definition["key_fields"]
        @scope = definition.fetch("scope", [])
        @parent_fields = definition.fetch("parent_fields", [])
        @operations = definition.fetch("operations")
        @public_id = @keyed && definition.dig("properties", "id", "type") == "string"
        @allocated_id = allocated_id && !@public_id
        @fields = @allocated_id ? definition.fetch("properties").except("id") : definition.fetch("properties")
        @max_records = max_records
      end

      # Whether the id is the record's own string (see the class comment), so a member route names
      # the record holding that id rather than a numbered key.
      def public_id?
        @public_id
      end

      def actions
        @operations.keys
      end

      def status(action)
        @operations.dig(action, "status") || { "create" => 201, "delete" => 204 }.fetch(action, 200)
      end

      # Allows a scope key only fixtures set, for a list scoped to it (see #list_scoped).
      def allow_scope(key)
        @scope |= [ key ]
      end

      # attachments: where file parameters are reported, since a record never stores their bytes.
      def create(state, params, attachments: [])
        attributes = attributes_from(declared("create"), params, attachments:)
        validate_model(attributes)
        store(state, attributes)
      end

      def find(state, id)
        key = key_of(state, id)
        present(key, stored(state, key))
      end

      def update(state, id, params, attachments: [])
        attributes = attributes_from(declared("update"), params, attachments:)
        return update_by_fields(state, attributes) if @key_fields

        key = key_of(state, id)
        records(state)[key] = stored(state, key).merge(attributes)
        present(key, records(state)[key])
      end

      def delete(state, id, params)
        attributes = attributes_from(declared("delete"), params)
        return delete_by_fields(state, attributes) if @key_fields

        key = key_of(state, id)
        stored(state, key)
        records(state).delete(key)
      end

      # A fixture record: made through create when the resource has one, so it is checked like a
      # request; otherwise checked against the entity's own field types. `_scope` sets its scope keys.
      def load(state, attributes)
        scope = attributes.fetch(FIXTURE_SCOPE, {})
        unknown = scope.is_a?(Hash) ? scope.keys - @scope : [ FIXTURE_SCOPE ]
        raise Error.bad_request("#{FIXTURE_SCOPE} may set only #{@scope.empty? ? "nothing for this resource" : @scope.join(", ")}; got #{unknown.join(", ")}") if unknown.any?

        attributes = attributes.except(FIXTURE_SCOPE)
        creatable = @operations.key?("create")
        carried = creatable ? scope.slice(*declared("create").keys) : {}
        extra = scope.except(*carried.keys)
        # A parent key a list requires is checked like that list parameter and kept as the value it
        # checks to ("05" as 5), which is what the list's parameter selects in any spelling it accepts.
        listed = @operations.dig("list", "params").to_h.slice(*extra.keys).select { |_, rule| rule["required"] }
        typed = listed.any? ? checked(listed, extra, request: false).fetch(SCOPE, {}) : {}
        record = creatable ? create(state, attributes.merge(carried)) : store(state, attributes_from(@fields, attributes, request: false))
        if extra.any?
          stored = records(state)[state.last_ids[@resource]]
          stored[SCOPE] = stored.fetch(SCOPE, {}).merge(extra.transform_values(&:to_s)).merge(typed)
        end
        record
      end

      # Pages through records in creation order and returns [ records, next cursor or nil ]. The
      # cursor records the last position returned, so records created during a traversal appear on
      # later pages, records deleted before being reached are skipped, and none is returned twice.
      # The list's scope keys, parent fields and key fields select records equal to them (structural
      # scoping), and its cursors are valid only for that selection; anything else, filtering and
      # sorting included, is refused.
      def list(state, params, instance)
        declared = declared("list")
        structural = declared.keys & (@scope + @parent_fields + Array(@key_fields))
        unsupported = (params.keys & declared.keys) - PAGINATION_PARAMS - structural
        raise Error.not_supported("Simulation does not support filtering or sorting; unsupported list parameters: #{unsupported.join(", ")}") if unsupported.any?

        wanted = checked(declared.slice(*structural), params.slice(*structural))
        page(state, params, instance, selection_scope(wanted)) { |attributes| matches?(attributes, wanted) }
      end

      # Whether the list is declared to answer one entity instead of an array ("array": false), which
      # #find_by_fields answers.
      def lookup?
        @operations.dig("list", "array") == false
      end

      # A list declared to answer one entity, such as the decimal-compat fixture's ListFoos, is a lookup
      # by the record's own fields, as key_fields are: each supplied list parameter is checked like a
      # create parameter and must be a field, and the answer is the one record holding exactly those
      # values (a decimal's exact text, an array element by element). None gets 404; more than one is
      # not simulated, since which one would be answered is not known. This is the simulator's reading
      # of the schema's shape for a synthetic fixture, not the behavior of any Files.com endpoint.
      def find_by_fields(state, params)
        wanted = checked(declared("list"), params)
        keys = records(state).select { |_, record| wanted.all? { |name, value| record.key?(name) && record[name] == value } }.keys
        raise Error.not_found if keys.empty?
        raise Error.not_supported("#{keys.size} #{@resource} hold these values; which one the list would answer is not simulated") if keys.size > 1

        present(keys.first, records(state)[keys.first])
      end

      # A list scoped by an explicit rule (schema.json "scoped_lists"): the records whose field or
      # scope key equals the route's value, or whose field is one of fixed values, and with the
      # rule's "ancestors" flag also those at the value's ancestor paths.
      def list_scoped(state, params, instance, id, rule, value)
        declared = rule.fetch("params")
        allowed = PAGINATION_PARAMS + [ rule.fetch("from", "path"), rule["ancestors"] ].compact
        unsupported = (params.keys & declared.keys) - allowed
        raise Error.not_supported("Simulation does not support these parameters on #{id}: #{unsupported.join(", ")}") if unsupported.any?

        ancestors = rule["ancestors"] && Coercion.boolean(params.fetch(rule["ancestors"], false))
        raise Error.bad_request("#{rule["ancestors"]} is invalid") if ancestors.equal?(Coercion::INVALID)

        accepted = rule["values"] || (ancestors ? ancestor_paths(value) << value : [ value ])
        scope = "#{@resource}@#{id}@#{Digest::SHA256.hexdigest(accepted.join("\0"))[0, 16]}"
        page(state, params, instance, scope) { |attributes| accepted.include?(scoped_value(attributes, rule)) }
      end

      def count(state)
        records(state).size
      end

      # Checks parameters against declared rules and returns the attributes they set; see #attributes_from.
      def checked(declared, params, attachments: [], request: true)
        attributes_from(declared, params, attachments:, request:)
      end

      private

      def declared(action)
        @operations.fetch(action).fetch("params")
      end

      # The model validations the simulator represents (MODEL_VALIDATIONS), after the parameters were
      # admitted and before anything is stored.
      def validate_model(attributes)
        failures = MODEL_VALIDATIONS.fetch(@resource, []).filter_map { |field, key, message, blank| [ field, key, message ] if blank.call(attributes[field]) }
        raise Error.model_save_error(failures) if failures.any?
      end

      def records(state)
        state.records[@resource] ||= {}
      end

      def value_of(attributes, name)
        attributes.key?(name) ? attributes[name] : attributes.dig(SCOPE, name)
      end

      # What a scoped list compares: the record's scope key, or its field as a string (a route's
      # value is part of its path).
      def scoped_value(attributes, rule)
        return attributes.dig(SCOPE, rule["scope"]) if rule["scope"]

        held = value_of(attributes, rule["field"])
        held.is_a?(Integer) ? held.to_s : held
      end

      # The cursor scope of a list selection: the resource alone for an unselected list, else the
      # resource and a digest of the selected values in a fixed order.
      def selection_scope(wanted)
        return @resource if wanted.empty?

        canonical = wanted.sort.map { |name, value| [ name, value.is_a?(Hash) ? value.sort : value ] }
        "#{@resource}@#{Digest::SHA256.hexdigest(JSON.generate(canonical))[0, 16]}"
      end

      def matches?(attributes, wanted)
        wanted.all? do |name, value|
          name == SCOPE ? value.all? { |key, held| attributes.dig(SCOPE, key) == held } : attributes[name] == value
        end
      end

      # "a" and "a/b" for "a/b/c", with "" for the root first.
      def ancestor_paths(path)
        names = path.split("/")
        [ "" ] + (1...names.size).map { |count| names.first(count).join("/") }
      end

      def page(state, params, instance, scope, &)
        per_page = page_size(params["per_page"])
        after = cursor_position(state.profile.token_of(params["cursor"]), params["cursor"], scope, instance, state.epoch, per_page)
        keys = records(state).each_key.lazy.select { |key| key > after && yield(records(state)[key]) }.first(per_page + 1)
        shown = keys.first(per_page)
        next_cursor = state.profile.cursor(Token.encode(scope, instance, state.epoch, per_page, shown.last)) if keys.size > per_page
        [ shown.map { |key| present(key, records(state)[key]) }, next_cursor ]
      end

      def store(state, attributes)
        raise Error.limit_exceeded(409, "The simulator already holds #{@max_records} #{@resource} (FILES_MOCK_MAX_RECORDS)") if count(state) >= @max_records
        raise Error.bad_request("id #{attributes["id"].inspect} is already held by another #{@resource} record") if @public_id && !attributes["id"].nil? && key_of(state, attributes["id"])

        key = state.last_ids[@resource] = state.last_ids.fetch(@resource, 0) + 1
        records(state)[key] = attributes
        present(key, attributes)
      end

      def stored(state, key)
        records(state).fetch(key) { raise Error.not_found }
      end

      # The private key of the record a member route names: its id, or for a string id the key of the
      # record holding that id (nil when none does).
      def key_of(state, id)
        return id unless @public_id
        return unless id.is_a?(String)

        records(state).find { |_, attributes| attributes["id"] == id }&.first
      end

      # The records whose key fields equal the request's; PATCH and DELETE require them all.
      def matching(state, attributes)
        wanted = attributes.slice(*@key_fields)
        keys = records(state).select { |_, record| wanted.all? { |name, value| record[name] == value } }.keys
        raise Error.not_found if keys.empty?

        keys
      end

      def update_by_fields(state, attributes)
        keys = matching(state, attributes)
        keys.each { |key| records(state)[key] = records(state)[key].merge(attributes) }
        present(keys.first, records(state)[keys.first])
      end

      def delete_by_fields(state, attributes)
        matching(state, attributes).each { |key| records(state).delete(key) }
      end

      # Returns the attributes to store, or raises before anything changes. An explicit null clears an
      # optional field. Scope keys are kept under SCOPE; file parameters are checked and reported to
      # `attachments`, never stored. A request's string for an array is first read as the API's parameter
      # coercion reads it (Coercion.request_array), so a blank [JSON] array arrives as an explicit null
      # would; `request: false` checks values exactly as given, as fixture answers and entity fields are.
      def attributes_from(declared, params, attachments: [], request: true)
        # An allocated id is never taken from what is supplied, and a request's string id only names
        # the record in its path: a record gets its string id from a fixture.
        route_id = @allocated_id || (@public_id && request)
        supplied = params.slice(*declared.keys)
        supplied = supplied.except("id") if route_id
        unsimulated = supplied.keys.reject { |name| simulated?(name, declared[name]) }
        raise Error.not_supported("Simulation does not support these parameters: #{unsimulated.join(", ")}") if unsimulated.any?

        errors = []
        attributes = {}
        files = []
        declared.each do |name, rule|
          next if name == "id" && route_id

          sent = request ? Coercion.request_array(Coercion.for(rule), supplied[name], json: JSON_ARRAYS.fetch(@resource, []).include?(name)) : supplied[name]
          if sent.nil?
            errors << "#{name} is missing" if rule["required"] && !(supplied.key?(name) && MODEL_VALIDATIONS.key?(@resource))
            attributes[name] = nil if supplied.key?(name)
            next
          end

          value = Coercion.public_send(Coercion.for(rule), sent)
          if value.equal?(Coercion::INVALID)
            errors << "#{name} is invalid"
          elsif rule["enum"] && !rule["enum"].include?(value)
            errors << "#{name} does not have a valid value"
          elsif value.is_a?(Coercion::Attachment)
            files << value.with(param: name)
          else
            attributes[name] = value
          end
        end
        raise Error.bad_request(errors.join(", ")) if errors.any?

        attachments.concat(files)
        kept = attributes.slice(*@fields.keys)
        scope = attributes.slice(*(@scope - @fields.keys))
        scope.empty? ? kept : kept.merge(SCOPE => scope.transform_values(&:to_s))
      end

      def simulated?(name, rule)
        (@fields.key?(name) || name.match?(WRITE_ONLY) || @scope.include?(name) || rule["type"] == "file") && Coercion.for(rule)
      end

      def present(key, attributes)
        @fields.each_key.with_object(@keyed && !@public_id ? { "id" => key } : {}) do |field, record|
          record[field] = attributes[field] if attributes.key?(field)
        end
      end

      def page_size(value)
        return DEFAULT_PER_PAGE if value.nil? || value == ""

        size = Coercion.int32(value)
        raise Error.bad_request("per_page is invalid") if size.equal?(Coercion::INVALID)
        raise Error.request_params_invalid("per_page must be greater than or equal to 1") if size < 1
        raise Error.request_params_invalid("per_page must be less than or equal to #{MAX_PER_PAGE}") if size > MAX_PER_PAGE

        size
      end

      # Cursors are valid only for this list (resource, and a scoped list's route and value),
      # simulator process, reset epoch and page size.
      def cursor_position(token, sent, scope, instance, epoch, per_page)
        return 0 if sent.nil? || sent == ""

        last = Token.values(token, scope, instance, epoch, per_page)
        raise Error.invalid_cursor unless last&.size == 1 && last.first.match?(/\A[0-9]+\z/)

        Integer(last.first, 10)
      end
    end

    # A record the API keeps exactly one of at a fixed path, such as the site: GET returns it and
    # PATCH changes it, checked like a record update. It holds only what fixtures and updates set.
    class Singleton
      attr_reader :resource, :path, :operations

      def initialize(resource, definition)
        @resource = resource
        @path = definition.fetch("path")
        @operations = definition.fetch("operations")
        @fields = definition.fetch("properties")
        @checks = Records.new(resource, definition.merge("key" => nil), max_records: 1)
      end

      def actions
        @operations.keys
      end

      def status(_action)
        200
      end

      def get(state)
        present(state.singletons.fetch(@resource, {}))
      end

      def update(state, params, attachments: [])
        changes = @checks.checked(@operations.fetch("update").fetch("params"), params, attachments:)
        state.singletons[@resource] = state.singletons.fetch(@resource, {}).merge(changes)
        get(state)
      end

      # Fixture values, checked against the entity's own field types.
      def load(state, attributes)
        state.singletons[@resource] = @checks.checked(@fields, attributes, request: false)
      end

      private

      def present(attributes)
        @fields.each_key.with_object({}) { |field, record| record[field] = attributes[field] if attributes.key?(field) }
      end
    end

    # Records keyed by a path in the site's namespace, such as styles (/styles/{path}): found and
    # deleted by that path, and changed with the update rules, the first change creating the record
    # with the next id. The path must be in the form the API keeps paths in (Namespace), but it is
    # never checked against the files and folders held, as nothing follows a record's references.
    class PathRecords
      attr_reader :resource, :path, :operations

      def initialize(resource, definition, namespace:, max_records:)
        @resource = resource
        @path = definition.fetch("path")
        @operations = definition.fetch("operations")
        @fields = definition.fetch("properties").except("id", "path")
        @entity_fields = @fields
        @namespace = namespace
        @max_records = max_records
        @checks = Records.new(resource, definition.merge("key" => nil, "path" => @path), max_records:)
      end

      def actions
        @operations.keys
      end

      def status(action)
        @operations.dig(action, "status") || { "delete" => 204 }.fetch(action, 200)
      end

      def find(state, path)
        present(path, records(state).fetch(key(path)) { raise Error.not_found })
      end

      def update(state, path, params, attachments: [])
        name = key(path)
        changes = @checks.checked(@operations.fetch("update").fetch("params").except("path"), params, attachments:)
        existing = records(state)[name]
        raise Error.limit_exceeded(409, "The simulator already holds #{@max_records} #{@resource} (FILES_MOCK_MAX_RECORDS)") if existing.nil? && records(state).size >= @max_records

        records(state)[name] = (existing || { "id" => state.last_ids[@resource] = state.last_ids.fetch(@resource, 0) + 1 }).merge(changes)
        present(name, records(state)[name])
      end

      def delete(state, path, _params)
        records(state).delete(key(path)) || raise(Error.not_found)
      end

      # A fixture: { "path", fields... }, checked against the entity's own field types.
      def load(state, attributes)
        path = attributes["path"]
        raise Error.bad_request("path is missing") unless path.is_a?(String) && !path.empty?

        unknown = attributes.keys - @entity_fields.keys - [ "path" ]
        raise Error.bad_request("unknown fields: #{unknown.join(", ")}") if unknown.any?

        name = key(path)
        raise Error.limit_exceeded(409, "The simulator already holds #{@max_records} #{@resource} (FILES_MOCK_MAX_RECORDS)") if !records(state).key?(name) && records(state).size >= @max_records

        fields = @checks.checked(@entity_fields, attributes.except("path"), request: false)
        records(state)[name] = (records(state)[name] || { "id" => state.last_ids[@resource] = state.last_ids.fetch(@resource, 0) + 1 }).merge(fields)
        present(name, records(state)[name])
      end

      def count(state)
        records(state).size
      end

      private

      def key(path)
        @namespace.request_path(path)
      end

      def records(state)
        state.path_records[@resource] ||= {}
      end

      def present(path, record)
        @fields.each_key.with_object({ "id" => record["id"], "path" => path }) { |field, shown| shown[field] = record[field] if record.key?(field) }
      end
    end

    # Read-only operations whose answer a test supplies as a reset fixture (fixtures.responses),
    # because it depends on configuration or providers the simulator does not hold, such as a site's
    # usage. The fixture is checked against the entity's field types; an operation with required
    # parameters takes an object mapping each parameter value (joined with "/") to its answer. An
    # array answer is paged like a list. Without a fixture the operation gets 501: nothing is invented.
    class FixtureResponses
      # Known keys one lookup fixture may list.
      MAX_KNOWN_KEYS = 10_000
      KNOWN = true

      attr_reader :id, :operation

      # A definition without an "entity" is a lookup: its fixture lists the known keys, and a request
      # gets 204 with no body for one of them and 404 for any other key.
      def initialize(id, definition)
        @id = id
        @operation = definition
        @keys = definition.fetch("keys")
        @array = definition.fetch("array")
        @lookup = definition["entity"].nil?
        # A fixture's "id" is answer data, checked like every other field, never an allocated one.
        @checks = Records.new(id, { "path" => definition.fetch("path"), "key" => nil, "operations" => {}, "properties" => definition.fetch("properties") }, max_records: 1, allocated_id: false)
        @fields = definition.fetch("properties")
      end

      def lookup?
        @lookup
      end

      def load(state, value)
        return load_known_keys(state, value) if @lookup

        answers = @keys.empty? ? { "" => value } : value
        raise Error.bad_request("must map each #{@keys.join("/")} value to an answer") unless answers.is_a?(Hash)

        state.responses[@id] = answers.to_h { |key, answer| [ key.to_s, check(answer) ] }
        answers.size
      end

      # Returns [ answer, next cursor or nil ]. `values` holds the route's values over the request's own.
      # A required parameter left out fails the API's parameter validation (a bare bad-request with
      # Grape's message) before anything else; one sent null or empty passes it, as a string parameter
      # needs only to be there. An empty value is part of the key like any other ("3/" for run 3 and an
      # empty node_id); a null names no fixture key, since every key is a string.
      def answer(state, values, params, instance)
        missing = @keys.reject { |name| values.key?(name) }
        raise Error.bad_request(missing.map { |name| "#{name} is missing" }.join(", ")) if missing.any?

        unsupported = params.keys & (@operation.fetch("params").keys - @keys - Records::PAGINATION_PARAMS)
        raise Error.not_supported("Simulation does not support these parameters on #{@id}: #{unsupported.join(", ")}") if unsupported.any?

        answers = state.responses[@id] or raise Error.not_supported("#{@id} answers only from a fixture; reset with fixtures.responses[#{@id.inspect}]")
        raise Error.not_found if @keys.any? { |name| values[name].nil? }

        key = @keys.map { |name| values[name].to_s }.join("/")
        answer = answers.fetch(key) { raise Error.not_found }
        return [ answer, nil ] unless @array

        per_page = params["per_page"] ? Coercion.int32(params["per_page"]) : Records::DEFAULT_PER_PAGE
        raise Error.request_params_invalid("per_page must be from 1 to #{Records::MAX_PER_PAGE}") unless per_page.is_a?(Integer) && per_page.between?(1, Records::MAX_PER_PAGE)

        start = params["cursor"].to_s.empty? ? 0 : cursor_index(state.profile.token_of(params["cursor"]), key, instance, state.epoch, per_page)
        page = answer[start, per_page] || []
        more = start + per_page < answer.size
        [ page, (state.profile.cursor(Token.encode("#{@id}@#{key}", instance, state.epoch, per_page, start + per_page)) if more) ]
      end

      private

      # A lookup fixture: the known keys (the required parameters' values joined with "/"), each a string.
      def load_known_keys(state, value)
        valid = value.is_a?(Array) && value.size <= MAX_KNOWN_KEYS && value.all? { |key| key.is_a?(String) && !key.empty? } && value.uniq.size == value.size
        raise Error.bad_request("must list at most #{MAX_KNOWN_KEYS} distinct, non-empty #{@keys.join("/")} strings") unless valid

        state.responses[@id] = value.to_h { |key| [ key, KNOWN ] }
        value.size
      end

      def check(answer)
        items = @array ? answer : [ answer ]
        raise Error.bad_request(@array ? "must be an array of objects" : "must be an object") unless items.is_a?(Array) && items.all?(Hash)

        unknown = items.flat_map(&:keys).uniq - @fields.keys
        raise Error.bad_request("unknown fields: #{unknown.join(", ")}") if unknown.any?

        checked = items.map { |item| @checks.checked(@fields, item, request: false) }
        @array ? checked : checked.first
      end

      def cursor_index(token, key, instance, epoch, per_page)
        values = Token.values(token, "#{@id}@#{key}", instance, epoch, per_page)
        raise Error.invalid_cursor unless values&.size == 1 && values.first.match?(/\A[0-9]+\z/)

        Integer(values.first, 10)
      end
    end
  end
end
