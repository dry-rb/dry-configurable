module Dry
  module Configurable

    # @private
    class NullConfig
      def initialize
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

      EQUAL_END = /=$/

      def method_missing(method_name, *args, &block)
        to_return = self
        if method_name.to_s.match(EQUAL_END)
          key = method_name.to_s.gsub(EQUAL_END, '').to_sym
          schema[key] = args.first
        else
          null_config = self.class.new
          schema[method_name] = null_config
          to_return = null_config
        end
        to_return
      end

      private
      attr_reader :schema
    end
  end
end
