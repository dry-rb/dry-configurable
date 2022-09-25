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
        raise FrozenError, "can't modify frozen config" if config.frozen?

        raise ArgumentError, "you need to pass a block" unless block_given?

        # Create copy of config only if we're configuring for the first time (in this case, we've
        # likely inherited it and need to make a distinct local copy).
        to_configure = _configured? ? config : config.dup
        to_configure.configure(&block)

        # On first configure, only reassign new config if it is changed from the one we already
        # have. If it's unchanged, save the memory and don't reassign.
        if !_configured? && to_configure != @config
          @config = to_configure
          _configured!
        end

        self
      end

      # Finalize and freeze configuration
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def finalize!(freeze_values: false)
        # TODO: need tests for this
        unless _configured?
          @config = config.dup
          _configured!
        end

        # FIXME: freeze_values won't really work here? need a deep_dup?
        config.finalize!(freeze_values: freeze_values)

        self
      end

      private

      def _configured?
        instance_variable_defined?(:@_configured) && @_configured
      end

      def _configured!
        @_configured = true
      end
    end
  end
end
