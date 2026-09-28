module FilesMockServer
  module Simulation
    # Converts request values to the types the Files.com API schema declares, accepting what the API's
    # own parameter coercion accepts. Each converter returns the converted value, or INVALID for a value
    # the API would reject. INVALID is distinct from nil because an explicit null is a valid value that
    # clears an optional field.
    module Coercion
      # [ Swagger-derived type, format ] => converter. Other combinations are not simulated.
      BY_TYPE = {
        [ "string", nil ] => :string,
        [ "string", "date-time" ] => :date_time,
        [ "boolean", nil ] => :boolean,
        [ "int64", nil ] => :int64,
        [ "int64", "int64" ] => :int64,
        [ "int64", "int32" ] => :int32,
      }.freeze
      INVALID = Object.new.freeze
      BOOLEANS = { true => true, false => false, "true" => true, "false" => false }.freeze
      DATE_TIME = /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?(Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)\z/
      UTC_DATE_TIME = /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?(Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)?\z/

      module_function

      # The converter for a schema parameter rule, or nil when the simulator does not understand its type.
      def for(rule)
        BY_TYPE[[ rule["type"], rule["format"] ]]
      end

      def string(value)
        value.is_a?(String) && value.valid_encoding? ? value : INVALID
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

      # Requires an explicit UTC offset so results never depend on the host time zone; returns UTC ISO 8601 like the API.
      def date_time(value)
        parse_date_time(value, DATE_TIME)
      end

      # Like date_time, but reads a timestamp without an offset as UTC, as the API reads the naive UTC
      # provided_mtime that the Python SDK's upload_file sends.
      def utc_date_time(value)
        parse_date_time(value, UTC_DATE_TIME)
      end

      # DateTime rejects impossible dates such as February 30, and the field comparison refuses values it would
      # otherwise roll over, such as 24:00 or a 60th second, instead of storing a different moment.
      def parse_date_time(value, format)
        return INVALID unless value.is_a?(String) && format.match?(value)

        parsed = DateTime.iso8601(value)
        return INVALID unless parsed.strftime("%FT%T") == value[0, 19]

        parsed.new_offset(0).strftime("%FT%TZ")
      rescue ArgumentError
        INVALID
      end

      def integer(value, bound)
        value = Integer(value, 10) if value.is_a?(String) && value.match?(/\A-?[0-9]+\z/)
        value.is_a?(Integer) && value >= -bound && value < bound ? value : INVALID
      end
    end
  end
end
