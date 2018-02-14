module Dry
  module Configurable

    # @private
    class NullConfig
      def self.from(struct_class)
        keys = extract_keys(struct_class, [])
        new(keys)
      end

      def self.extract_keys(struct_class, keys)
        struct_class.attribute_names.each do |key|
          type = struct_class.schema[key]
          keys << key
          if type.respond_to?(:schema)
            extract_keys(type, keys)
          end
        end
        keys
      end

      def initialize(keys)
        @keys = keys
        @schema = {}
      end

      def to_config
        schema.each_with_object({}) do |(key, value), hash|
          case value
          when NullConfig
            hash[key] = value.to_config
          else
            hash[key] = value
          end
        end
      end

      EQUAL = "=".freeze

      def method_missing(method_name, *args, &block)
        to_return = self
        key = method_name.to_s
        index = key.rindex(EQUAL)
        key = index ? key[0, index].to_sym : method_name
        super unless keys.include?(key)
        if index
          schema[key] = args.first
        else
          null_config = self.class.new(keys)
          schema[key] = null_config
          to_return = null_config
        end
        to_return
      end

      private
      attr_reader :schema, :keys
    end
  end
end
