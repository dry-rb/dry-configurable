module Dry
  module Configurable
    # @private
    class NullConfig < Config
      transform_types do |type|
        if type.is_a?(Class) && type <= Dry::Struct || type.default?
          type
        elsif type.optional?
          type.default(nil)
        else
          type.optional.default(nil)
        end
      end

      class << self
        def setting(name, type = nil, &block)
          super

          define_method("#{name}=") do |value|
            @attributes = @attributes.merge(name => value)
          end
        end

        def conditions
          @conditions ||= {}
        end

        def condition(name, &block)
          conditions[name] = block
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        self.class.conditions.key?(method_name) || super
      end

      def method_missing(method_name, args, &block)
        super unless self.class.conditions.key?(method_name)
        yield if self.class.conditions[method_name].call(args)
      end
    end
  end
end
