module Dry
  module Configurable
    module Helpers
      def type?(type)
        type && type.is_a?(Dry::Types::Type)
      end
    end
  end
end
