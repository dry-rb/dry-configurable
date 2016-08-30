module Dry
  module Configurable
    # @private
    class Config
      def initialize(hash)
        hash.each do |key, value|
          ivar_name = "@#{key}"

          singleton_class.__send__(:define_method, key) do
            if instance_variable_defined?(ivar_name)
              instance_variable_get(ivar_name)
            else
              if value.is_a?(::Dry::Configurable::Config::Value::Lazy)
                __send__("#{key}=", value.call(self))
              else
                __send__("#{key}=", value)
              end
            end
          end

          singleton_class.__send__(:define_method, "#{key}=") do |val|
            instance_variable_set(ivar_name, val)
          end
        end
      end
    end
  end
end
