module Dry
  module Configurable

    # @private
    class DefaultValues
      def self.call(struct_class, schema = {})
        struct_class.attribute_names.each do |key|
          type = struct_class.schema[key]
          schema[key] = {} unless type.default?
          if type.respond_to?(:schema)
            call(type, schema[key])
          end
        end
        schema
      end
    end
  end
end
