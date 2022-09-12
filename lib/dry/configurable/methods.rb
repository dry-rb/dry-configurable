# frozen_string_literal: true

module Dry
  module Configurable
    # Common API for both classes and instances
    #
    # @api public
    module Methods
      # @api public
      def configure(&block)
        # TODO: We'll want some other signal to tell that the user has _explicitly_ frozen their
        # config. `finalized?` maybe?
        raise FrozenConfig, "Cannot modify frozen config" if frozen?

        raise ArgumentError, "you need to pass a block" unless block_given?

        # yield(config)
        config.to_update(&block)

        # config.finalize!(freeze_values: true)

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
