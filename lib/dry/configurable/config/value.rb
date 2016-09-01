module Dry
  module Configurable
    class Config
      # @private
      class Value
        # @private
        NONE = ::Object.new.freeze

        attr_reader :name, :processor

        def initialize(name, value, processor)
          @name, @value, @processor = name, value, processor
        end

        def value
          none? ? nil : @value
        end

        def none?
          @value.eql?(::Dry::Configurable::Config::Value::NONE)
        end
      end
    end
  end
end
