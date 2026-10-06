module FilesMockServer
  module Simulation
    # Converts request values to the types the Files.com API schema declares, accepting what the API's
    # own parameter coercion accepts. Each converter returns the converted value, or INVALID for a value
    # the API would reject. INVALID is distinct from nil because an explicit null is a valid value that
    # clears an optional field.
    module Coercion
      # [ Swagger-derived type, format ] => converter, for parameters and for entity fields (which
      # name date-time, date, email and decimal as their type). Other combinations are not simulated.
      BY_TYPE = {
        [ "string", nil ] => :string,
        [ "string", "date-time" ] => :date_time,
        [ "date-time", "date-time" ] => :date_time,
        [ "date", "date" ] => :date,
        [ "email", "email" ] => :string,
        [ "boolean", nil ] => :boolean,
        [ "int64", nil ] => :int64,
        [ "int64", "int64" ] => :int64,
        [ "int64", "int32" ] => :int32,
        [ "double", "double" ] => :double,
        [ "decimal", "decimal" ] => :decimal,
        [ "object", nil ] => :object,
        [ "array(string)", nil ] => :strings,
        [ "array(int64)", nil ] => :integers,
        [ "array(decimal)", nil ] => :decimals,
        [ "array(object)", nil ] => :objects,
      }.freeze
      # A decimal string the API's parameter coercion reads (Grape's BigDecimal is dry-types
      # Params::Decimal, which checks the text with Float() and converts the original text with
      # to_d): an exact base-10 string, optionally with an ordinary e or E exponent ("1E-7",
      # "1.5E+3"). Only these ordinary forms are accepted, not all that Float() or BigDecimal read
      # (such as "1_000", ".5" or surrounding spaces), and the text is kept as sent, never converted
      # through a float or expanded.
      DECIMAL = /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\z/
      DATE = /\A\d{4}-\d\d-\d\d\z/
      INVALID = Object.new.freeze
      BOOLEANS = { true => true, false => false, "true" => true, "false" => false }.freeze
      # Also "True" and "False", which .NET's Boolean.ToString() writes and the API's parameter
      # coercion (dry-types Params::Bool) reads as booleans. Only the operations in
      # Files::DOTNET_BOOLEAN_OPERATIONS take them, wherever the request carries the parameter.
      DOTNET_BOOLEANS = BOOLEANS.merge("True" => true, "False" => false).freeze
      DATE_TIME = /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?(Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)\z/
      UTC_DATE_TIME = /\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\d(\.\d+)?(Z|[+-](?:[01]\d|2[0-3]):[0-5]\d)?\z/
      # The UTC form .NET's DateTime.ToString("u") writes, such as "2026-09-24 00:00:00Z".
      UNIVERSAL_SORTABLE = /\A\d{4}-\d\d-\d\d \d\d:\d\d:\d\dZ\z/
      # The forms Ruby's Time#to_s writes, which the Ruby SDK sends: "2026-09-24 07:11:22 -0700", or
      # "2026-09-24 14:11:22 UTC" for a UTC time.
      RUBY_TIME = /\A(\d{4}-\d\d-\d\d) (\d\d:\d\d:\d\d) (?:UTC|([+-](?:[01]\d|2[0-3]))([0-5]\d))\z/

      # The most zeros a JSON number's exact plain form (such as "1000" for 1e3, or "0.001" for 1e-3)
      # may add to its significant digits. A tiny exponent would otherwise make a huge string: a
      # 27-byte body holding 1e100000 once became 100,001 bytes. The padding is computed from the
      # number's exponent before any string is built, so every number's text is at most this many
      # bytes (plus a sign and point) longer than its significant digits: numeric text stays within
      # about seven times the request body, which is itself within FILES_MOCK_MAX_BODY_BYTES.
      MAX_ZERO_PADDING = 32
      # The converters of array parameters (see #request_array).
      ARRAYS = %i[strings integers decimals objects].freeze

      # An ordinary JSON number inside an object or array value. Request bodies are parsed with
      # BigDecimal numbers so that schema decimals stay exact; inside a value the schema does not type,
      # a number is kept at that exact value and written back as a JSON number, never a string: in
      # plain form, or, when that would pad it with more than MAX_ZERO_PADDING zeros, in BigDecimal's
      # exponent form (such as 0.1e100001), which is the same exact JSON number.
      class JsonNumber
        attr_reader :text

        def initialize(value)
          @text = Coercion.zero_padding(value) > MAX_ZERO_PADDING ? value.to_s : value.to_s("F").sub(/\.0\z/, "")
        end

        def to_json(*) = @text
        def ==(other) = other.is_a?(JsonNumber) && other.text == text
        alias eql? ==
        def hash = text.hash
      end

      # A file parameter's upload, as the simulator reports it: never its bytes. `filename` is the
      # name the server sees; `raw_filename` is the name exactly as the request carried it (a multipart
      # part's Content-Disposition, before any decoding), and `encoding` says which form carried it.
      Attachment = Data.define(:param, :filename, :raw_filename, :content_type, :size, :sha256, :encoding) do
        def as_json = to_h.transform_keys(&:to_s).compact
      end
      # The JSON file object Files.com accepts for a file parameter, when multipart cannot carry the
      # request's other values: { "encoded_content" (Base64), "filename", "type" }.
      FILE_OBJECT = %w[encoded_content filename type].freeze

      module_function

      # The converter for a schema parameter or field rule, or nil when the simulator does not
      # understand its type. A field holding another entity (its type is that entity's name) or a
      # hash is kept as a JSON object whose contents are not checked.
      def for(rule)
        type = rule["type"].to_s
        return :object if type.match?(/\A[A-Z]/) || type.start_with?("hash(")
        return :file if type == "file"

        BY_TYPE[[ type, rule["format"] ]]
      end

      def string(value)
        value.is_a?(String) && value.valid_encoding? ? value : INVALID
      end

      def boolean(value)
        BOOLEANS.fetch(value, INVALID)
      end

      # A boolean parameter of one of Files::DOTNET_BOOLEAN_OPERATIONS, from its query string or
      # its JSON body alike.
      def dotnet_boolean(value)
        DOTNET_BOOLEANS.fetch(value, INVALID)
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

      # Like date_time, but for a file's or folder's provided_mtime: it reads a timestamp without an
      # offset as UTC, as the API reads the naive UTC time the Python SDK's upload_file sends, and it
      # accepts the fixed-width "yyyy-MM-dd HH:mm:ssZ" UTC time the .NET SDK sends and the Ruby
      # SDK's RUBY_TIME. Only the ISO form may leave out the offset.
      def utc_date_time(value)
        if value.is_a?(String) && UNIVERSAL_SORTABLE.match?(value)
          value = value.sub(" ", "T")
        elsif value.is_a?(String) && (ruby = RUBY_TIME.match(value))
          value = "#{ruby[1]}T#{ruby[2]}#{ruby[3] ? "#{ruby[3]}:#{ruby[4]}" : "Z"}"
        end
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

      # A JSON number or a numeric string, as a float the API returns as a JSON number.
      def double(value)
        value = Float(value) if value.is_a?(String) && value.match?(/\A-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?\z/)
        value.is_a?(Numeric) && value.to_f.finite? ? value.to_f : INVALID
      end

      # A decimal string is kept exactly as sent, an exponent included; how the API spells a decimal
      # it returns, and what a field's precision and scale keep, are not simulated. A JSON number is
      # accepted too, as the API's parameter coercion accepts it, and kept exactly: request bodies are
      # parsed with BigDecimal numbers, so no binary rounding happens on the way in. A JSON number
      # whose exact string would pad it with more than MAX_ZERO_PADDING zeros is refused before that
      # string is built. The journal records which JSON type the client actually sent.
      def decimal(value)
        text = case value
               when String then value
               when Integer then value.to_s
               when BigDecimal then value.to_s("F").sub(/\.0\z/, "") if value.finite? && zero_padding(value) <= MAX_ZERO_PADDING
               end
        text&.match?(DECIMAL) ? text : INVALID
      end

      # How many zeros BigDecimal#to_s("F") adds to a finite value's significant digits, from its
      # exponent alone: trailing zeros before the point, or leading zeros after it.
      def zero_padding(value)
        return 0 if value.zero?

        exponent = value.exponent
        digits = value.n_significant_digits
        if exponent > digits then exponent - digits
        elsif exponent.negative? then -exponent
        else
          0
        end
      end

      def date(value)
        return INVALID unless value.is_a?(String) && DATE.match?(value)

        Date.iso8601(value).iso8601
      rescue Date::Error
        INVALID
      end

      def object(value)
        value.is_a?(Hash) ? plain(value) : INVALID
      end

      # A file parameter: a multipart file part (as App#request_params gives it) or the JSON file
      # object, with its Base64 decoded (strict, or MIME with line breaks). Returns an Attachment.
      def file(value)
        return INVALID unless value.is_a?(Hash)
        return multipart_file(value) if value.key?(:multipart)

        filename, type, content = value.values_at(*%w[filename type encoded_content])
        return INVALID unless (value.keys - FILE_OBJECT).empty? && content.is_a?(String) && [ filename, type ].all? { |text| text.nil? || text.is_a?(String) }

        bytes = content.match?(/\A[A-Za-z0-9+\/=]*\z/) ? content.unpack1("m0") : content.gsub(/\r?\n/, "").unpack1("m0")
        Attachment.new(param: nil, filename:, raw_filename: filename, content_type: type, size: bytes.bytesize, sha256: Digest::SHA256.hexdigest(bytes), encoding: "encoded_content")
      rescue ArgumentError
        INVALID
      end

      def multipart_file(value)
        bytes = value.fetch(:bytes)
        Attachment.new(param: nil, filename: value[:filename], raw_filename: value[:raw_filename], content_type: value[:type], size: bytes.bytesize,
                       sha256: Digest::SHA256.hexdigest(bytes), encoding: "multipart"
        )
      end

      # A JSON value with every BigDecimal (a JSON fraction) made a JsonNumber, at any depth.
      def plain(value)
        case value
        when Hash then value.transform_values { |item| plain(item) }
        when Array then value.map { |item| plain(item) }
        when BigDecimal then value.finite? ? JsonNumber.new(value) : value
        else value
        end
      end

      def strings(value)
        each_of(value) { |item| string(item) }
      end

      def integers(value)
        each_of(value) { |item| int64(item) }
      end

      def decimals(value)
        each_of(value) { |item| decimal(item) }
      end

      def objects(value)
        each_of(value) { |item| object(item) }
      end

      # How the API's parameter coercion reads a string a request sends for an array parameter, before
      # its members are checked. An array declared [String], [Integer], [BigDecimal] or [Hash] goes through
      # dry-types' params array (Grape's ArrayCoercer), which reads an empty string as an empty array
      # (Coercions::Params.to_ary). An array declared [JSON] is Grape's JsonArray instead (#json_array).
      # Swagger calls both an array of objects, so the caller says which (json:). Anything else is returned
      # as sent, for the converter to check. Only request parameters are read this way; a fixture's values
      # are checked exactly as given.
      def request_array(converter, value, json: false)
        return value unless ARRAYS.include?(converter) && value.is_a?(String)
        return json_array(value) if json

        value.empty? ? [] : value
      end

      # A string sent for an array declared [JSON], read as Grape's JsonArray reads it (Json.parse): a
      # string holding a blank line is no value, and any other is parsed as JSON, "null" to no value and a
      # single object wrapped in an array. The result is then checked as an array of objects, so a
      # malformed document, a scalar or a member that is not an object is invalid. Numbers are read as the
      # request body's are, so an encoded array is kept exactly as the same array sent directly (Grape
      # parses the string with Ruby's JSON defaults; what the model then keeps is not simulated).
      def json_array(text)
        return if text.match?(/^\s*$/)

        parsed = JSON.parse(text, decimal_class: BigDecimal)
        parsed.is_a?(Hash) ? [ parsed ] : parsed
      rescue JSON::ParserError
        INVALID
      end

      # An array whose every element converts; INVALID when it is not an array or any element is invalid.
      def each_of(value, &)
        return INVALID unless value.is_a?(Array)

        converted = value.map(&)
        converted.any? { |item| item.equal?(INVALID) } ? INVALID : converted
      end

      def integer(value, bound)
        value = Integer(value, 10) if value.is_a?(String) && value.match?(/\A-?[0-9]+\z/)
        value.is_a?(Integer) && value >= -bound && value < bound ? value : INVALID
      end
    end
  end
end
