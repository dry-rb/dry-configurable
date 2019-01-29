module Dry
  module Configurable
    class Config
      # @private
      class Value
        attr_reader :name, :processor

        def initialize(name, value, processor)
          @name = name.to_sym
          @value = value
          @processor = processor
        end

        def value
          Undefined.default(@value, nil)
        end

        def undefined?
          Undefined.eql?(@value)
        end

        def nested_config?
          @value.is_a?(::Dry::Configurable::NestedConfig)
        end
      end
    end
  end
end
