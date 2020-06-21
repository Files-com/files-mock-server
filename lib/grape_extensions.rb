module Grape
  module Validations
    module Types
      # Accept Base64Uploads as a File and coerce them to work like a normal File
      class File
        def coerce(input)
          if input.is_a?(ActiveSupport::HashWithIndifferentAccess) and input.key?(:encoded_content)
            Base64Upload.new(Base64.decode64(input[:encoded_content]), input[:filename], input[:type])
          else
            input
          end
        end

        def value_coerced?(value)
          value.is_a?(Base64Upload) ||
            (value.is_a?(::Hash) && value.key?(:tempfile) && value[:tempfile].is_a?(Tempfile))
        end
      end
    end

    # Handle Array params, e.g. `type: Array[File]`. Normal Grape validation behavior enforces the outer type (Array) but not the inner type (File). We want to coerce the inner type.
    class CoerceValidator < Base
      alias orig_coerce_value coerce_value
      alias orig_type type

      def coerce_value(val)
        output = orig_coerce_value(val)
        # Type could be an Array if the field is meant to be an array OR if multiple types are allowed
        # Primitive could be Array even when type is `Array` instead of `Array[TYPE]`
        if type.is_a?(Array) and @converter.primitive == Array
          inner_converter = Grape::Validations::Types.build_coercer(type.first)
          output.each_with_object([]) do |item, collection|
            collection << inner_converter.coerce(item)
          end
        else
          output
        end
      end

      # Override to account for Hash[String=>String] which has no `value`
      def type
        orig_result = orig_type
        if orig_result.nil? and @option[:type].is_a?(Hash)
          Virtus::Attribute.build(@option[:type])
        else
          orig_result
        end
      end
    end
  end
end
