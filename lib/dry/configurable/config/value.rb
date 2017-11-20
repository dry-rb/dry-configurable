module Dry
  module Configurable
    class Config
      # @private
      class Value
        # @private
        NONE = ::Object.new.freeze


        attr_reader :name, :processor, :preprocessor

        def initialize(name, value, processor, preprocessor)
          @name = name.to_sym
          @value = value
          @processor = processor
          @preprocessor = preprocessor
        end

        def value
          none? ? nil : @value
        end

        def process(value)
          value = preprocessor.(value)
          processor.(value)
        end

        def none?
          @value.equal?(::Dry::Configurable::Config::Value::NONE)
        end
      end
    end
  end
end
