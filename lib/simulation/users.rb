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
      # [ Swagger-derived type, format ] => coercion method. Other combinations are not simulated.
      COERCIONS = {
        [ "string", nil ] => :string,
        [ "string", "date-time" ] => :date_time,
        [ "boolean", nil ] => :boolean,
        [ "int64", nil ] => :int64,
        [ "int64", "int64" ] => :int64,
        [ "int64", "int32" ] => :int32,
      }.freeze
      BOOLEANS = { true => true, false => false, "true" => true, "false" => false }.freeze
      DATE_TIME = /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?(Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)\z/
      # Returned by the coercions below for a rejected value. It is distinct from nil because an explicit
      # null is a valid value that clears an optional field.
      INVALID = Object.new.freeze

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

          value = send(COERCIONS.fetch([ rule["type"], rule["format"] ]), supplied[name])
          if value.equal?(INVALID)
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
        (@fields.include?(name) || WRITE_ONLY_PARAMS.include?(name)) && COERCIONS.key?([ rule["type"], rule["format"] ])
      end

      def present(id, attributes)
        @fields.each_with_object({ "id" => id }) do |field, user|
          user[field] = attributes[field] if attributes.key?(field)
        end
      end

      def page_size(value)
        return DEFAULT_PER_PAGE if value.nil? || value == ""

        size = int32(value)
        raise Error.bad_request("per_page is invalid") if size.equal?(INVALID)
        raise Error.request_params_invalid("per_page must be greater than or equal to 1") if size < 1
        raise Error.request_params_invalid("per_page must be less than or equal to #{MAX_PER_PAGE}") if size > MAX_PER_PAGE

        size
      end

      # Cursors are opaque to clients and valid only for this resource, simulator process, reset epoch and page size.
      def encode_cursor(instance, epoch, per_page, last_id)
        [ RESOURCE, instance, epoch, per_page, last_id ].join(":").unpack1("H*")
      end

      def cursor_position(token, instance, epoch, per_page)
        return 0 if token.nil? || token == ""
        raise Error.invalid_cursor unless token.is_a?(String) && token.match?(/\A(?:[0-9a-f]{2}){1,128}\z/)

        fields = [ token ].pack("H*").split(":", -1)
        valid = fields.size == 5 && fields.first(4) == [ RESOURCE, instance, epoch.to_s, per_page.to_s ] && fields.last.match?(/\A[0-9]+\z/)
        raise Error.invalid_cursor unless valid

        Integer(fields.last, 10)
      end

      def string(value)
        value.is_a?(String) && value.valid_encoding? ? value : INVALID
      end

      # Requires an explicit UTC offset so results never depend on the host time zone; returns UTC ISO 8601 like the API.
      # DateTime rejects impossible dates such as February 30, and the field comparison refuses values it would
      # otherwise roll over, such as 24:00 or a 60th second, instead of storing a different moment.
      def date_time(value)
        return INVALID unless value.is_a?(String) && DATE_TIME.match?(value)

        parsed = DateTime.iso8601(value)
        return INVALID unless parsed.strftime("%FT%T") == value[0, 19]

        parsed.new_offset(0).strftime("%FT%TZ")
      rescue ArgumentError
        INVALID
      end

      def boolean(value)
        BOOLEANS.fetch(value, INVALID)
      end

      def int32(value)
        integer(value, 2**31)
      end

      def int64(value)
        integer(value, 2**63)
      end

      def integer(value, bound)
        value = Integer(value, 10) if value.is_a?(String) && value.match?(/\A-?[0-9]+\z/)
        value.is_a?(Integer) && value >= -bound && value < bound ? value : INVALID
      end
    end
  end
end
