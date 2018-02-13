module Dry
  module Configurable

    # @private
    class ProxySettings
      attr_reader :schema

      def initialize(settings, &block)
        @settings = settings
        @schema = {}
        instance_eval(&block)
      end

      def config(key, value = nil, &block)
        if settings.attribute?(key)
          value = block ? self.class.new(settings.schema[key], &block).schema : value
          schema[key] = value
        end
      end

      private
      attr_reader :settings
    end
  end
end
