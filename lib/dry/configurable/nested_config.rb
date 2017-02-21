module Dry
  module Configurable
    # @private
    class NestedConfig
      def initialize(klass)
        @klass = klass
      end

        # @private no, really...
      def create_config
        if @klass.instance_variables.include?(:@_config)
          @klass.__send__(:create_config)
        end
      end

      private

      def config
        @klass.config
      end

      def method_missing(method, *args, &block)
        config.respond_to?(method) ? config.public_send(method, *args, &block) : super
      end

      def respond_to_missing?(method, _include_private = false)
        config.respond_to?(method) || super
      end
    end
  end
end
