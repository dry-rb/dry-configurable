module Dry
  module Configurable
    class Config
      module Value
        # @private
        class Lazy
          attr_reader :value

          def initialize(value)
            @value = value
          end

          def call(config)
            value.call(config)
          end
        end
      end
    end
  end
end
