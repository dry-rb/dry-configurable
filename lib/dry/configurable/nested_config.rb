module Dry
  module Configurable
    # @private
    class NestedConfig
      def initialize(&block)
        @definition = block
      end

      # @private no, really...
      def create_config
        klass = ::Class.new { extend ::Dry::Configurable }
        klass.instance_exec(&@definition)
        klass.config
      end

      private

      def method_missing(method, *args, &block)
        config.respond_to?(method) ? config.public_send(method, *args, &block) : super
      end

      def respond_to_missing?(method, _include_private = false)
        config.respond_to?(method) || super
      end
    end
  end
end
