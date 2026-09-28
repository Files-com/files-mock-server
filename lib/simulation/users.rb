module FilesMockServer
  module Simulation
    # Users held in simulator memory. Parameters are checked against the Swagger metadata in
    # schema.json, but only a closed set of types and formats is understood: any other supplied
    # parameter is rejected as not simulated instead of being accepted and ignored.
    class Users
      RESOURCE = "users".freeze
      # Accepted and type-checked, but never stored, returned or journaled.
      WRITE_ONLY_PARAMS = %w[password password_confirmation change_password change_password_confirmation imported_password_hash].freeze
      PAGINATION_PARAMS = %w[cursor per_page].freeze
      # Files.com API list page sizes.
      DEFAULT_PER_PAGE = 1_000
      MAX_PER_PAGE = 10_000

      def initialize(schema, max_records:)
        operations = schema.fetch("operations")
        @params = %w[create list update delete].to_h { |action| [ action, operations.fetch("#{RESOURCE}.#{action}").fetch("params") ] }
        @fields = schema.fetch("entities").fetch(RESOURCE)
        @max_records = max_records
      end

      def create(state, params)
        attributes = attributes_from(@params["create"], params)
        raise Error.limit_exceeded(409, "The simulator already holds #{@max_records} users (FILES_MOCK_MAX_RECORDS)") if state.users.size >= @max_records

        id = state.last_user_id += 1
        state.users[id] = attributes
        present(id, attributes)
      end

      def find(state, id)
        present(id, stored(state, id))
      end

      def update(state, id, params)
        attributes = attributes_from(@params["update"], params)
        state.users[id] = stored(state, id).merge(attributes)
        present(id, state.users[id])
      end

      def delete(state, id, params)
        attributes_from(@params["delete"], params)
        stored(state, id)
        state.users.delete(id)
      end

      # Pages through users in ID (creation) order and returns [ users, next cursor or nil ]. The
      # cursor records the last ID returned, so users created during a traversal appear on later
      # pages, users deleted before being reached are skipped, and no user is returned twice.
      def list(state, params, instance)
        unsupported = (params.keys & @params["list"].keys) - PAGINATION_PARAMS
        raise Error.not_supported("Simulation does not support filtering or sorting; unsupported list parameters: #{unsupported.join(", ")}") if unsupported.any?

        per_page = page_size(params["per_page"])
        after_id = cursor_position(params["cursor"], instance, state.epoch, per_page)
        ids = state.users.each_key.lazy.select { |id| id > after_id }.first(per_page + 1)
        page = ids.first(per_page)
        next_cursor = encode_cursor(instance, state.epoch, per_page, page.last) if ids.size > per_page
        [ page.map { |id| present(id, state.users[id]) }, next_cursor ]
      end

      private

      def stored(state, id)
        state.users.fetch(id) { raise Error.not_found }
      end

      # Returns the attributes to store, or raises before anything changes. An explicit null clears an optional field.
      def attributes_from(declared, params)
        supplied = params.slice(*declared.keys).except("id")
        unsimulated = supplied.keys.reject { |name| simulated?(name, declared[name]) }
        raise Error.not_supported("Simulation does not support these parameters: #{unsimulated.join(", ")}") if unsimulated.any?

        errors = []
        attributes = {}
        declared.each do |name, rule|
          next if name == "id"

          if supplied[name].nil?
            errors << "#{name} is missing" if rule["required"]
            attributes[name] = nil if supplied.key?(name)
            next
          end

          value = Coercion.public_send(Coercion.for(rule), supplied[name])
          if value.equal?(Coercion::INVALID)
            errors << "#{name} is invalid"
          elsif rule["enum"] && !rule["enum"].include?(value)
            errors << "#{name} does not have a valid value"
          else
            attributes[name] = value
          end
        end
        raise Error.bad_request(errors.join(", ")) if errors.any?

        attributes.slice(*@fields)
      end

      def simulated?(name, rule)
        (@fields.include?(name) || WRITE_ONLY_PARAMS.include?(name)) && Coercion.for(rule)
      end

      def present(id, attributes)
        @fields.each_with_object({ "id" => id }) do |field, user|
          user[field] = attributes[field] if attributes.key?(field)
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

      # Cursors are valid only for this resource, simulator process, reset epoch and page size.
      def encode_cursor(instance, epoch, per_page, last_id)
        Token.encode(RESOURCE, instance, epoch, per_page, last_id)
      end

      def cursor_position(token, instance, epoch, per_page)
        return 0 if token.nil? || token == ""

        last_id = Token.values(token, RESOURCE, instance, epoch, per_page)
        raise Error.invalid_cursor unless last_id&.size == 1 && last_id.first.match?(/\A[0-9]+\z/)

        Integer(last_id.first, 10)
      end
    end
  end
end
