module Dry
  module Configurable
    class Config
      # @private
      class Value
        # @private
        NONE = ::Object.new.freeze

        attr_reader :name, :processor, :preprocessor

        def initialize(name, value, processor, preprocessor = nil)
          @name = name.to_sym
          @value = value
          @processor = processor
          @preprocessor = preprocessor
        end

        def value
          if none?
            nil
          else
            @value
          end
        end

        def none?
          @value.equal?(::Dry::Configurable::Config::Value::NONE)
        end
      end
    end
  end
end
