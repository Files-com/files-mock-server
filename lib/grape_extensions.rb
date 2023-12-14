module Grape
  module Validations
    module Types
      # Accept Base64Uploads as a File and coerce them to work like a normal File
      class File
        def self.parse(input)
          if input.is_a?(ActiveSupport::HashWithIndifferentAccess) and input.key?(:encoded_content)
            Base64Upload.new(Base64.decode64(input[:encoded_content]), input[:filename], input[:type])
          else
            input
          end
        end

        def self.parsed?(value)
          return true if value == "" # the frontend passes an empty string when creating a user for this value, and master accepts it as a valid file

          value.is_a?(Base64Upload) ||
            (value.is_a?(::Hash) && value.key?(:tempfile) && value[:tempfile].is_a?(Tempfile)) ||
            (value.is_a?(ActionDispatch::Http::UploadedFile) && value.tempfile.is_a?(Tempfile))
        end
      end
    end

    module Validators
      # Handle Array params, e.g. `type: Array[File]`. Normal Grape validation behavior enforces the outer type (Array) but not the inner type (File). We want to coerce the inner type.
      class CoerceValidator < Base
        alias orig_coerce_value coerce_value
        alias orig_type type

        def coerce_value(val)
          return nil if val.nil?

          if type == DateTime and val.to_s =~ /\A[0-9]+\Z/
            Time.at(val.to_i).to_datetime
          elsif type.is_a?(Array) and converter.instance_variable_get(:@coercer)&.primitive == Array
            # virtus wouldn't even get to this point. both type and coercer were #<Virtus::Attribute type=nil options=nil> so I don't think it was doing any checking at all
            # unfortunately, DRY types will choke on this and we have at least specs and probably behavior that actually depends on this - JimBob 11/13/2023
            return [ "" ] if val == [ "" ]

            o = orig_coerce_value([ *val ]) # virtus automatically turned "string" into ["string"] for these but dry doesn't
            return o if o.is_a?(Grape::Validations::Types::InvalidValue)

            inner_converter = Grape::Validations::Types.build_coercer(type.first)
            o.each_with_object([]) do |item, collection|
              if item.is_a? type.first
                collection << item
              else
                collection << inner_converter.call(item)
              end
            end
          else
            orig_coerce_value(val)
          end
        end

        # Override to account for Hash[String=>String] which has no `value`
        def type
          orig_result = orig_type
          if orig_result.nil? and @option[:type].is_a?(Hash)
            @option[:type]
          else
            orig_result
          end
        end
      end
    end
  end
end
