module Dry
  module Configurable
    # @private
    class Config < ::Struct
      def self.create(hash)
        self.new(*hash.keys).new(*hash.values)
      end
    end
  end
end
