# frozen_string_literal: true

module Dry
  module Configurable
    # Common API for both classes and instances
    #
    # @api public
    module Methods
      # @api public
      def configure(&block)
        raise FrozenError, "can't modify config on frozen #{self}" if frozen?

        raise ArgumentError, "you need to pass a block" unless block_given?

        new_config = config.dup.tap { |c| c.configure(&block) }
        @config = new_config unless new_config == @config

        self
      end

      # Finalize and freeze configuration
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def finalize!(freeze_values: false)
        config.finalize!(freeze_values: freeze_values)
        self
      end
    end
  end
end
