# frozen_string_literal: true

module Dry
  module Configurable
    # Common API for both classes and instances
    #
    # @api public
    module Methods
      # @api public
      def configure(&block)
        yield(config) if block
        config.finalize!
        self
      end

      # Finalize and freeze configuration
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def finalize!
        return self if config.frozen?
        config.finalize!
        self
      end
    end
  end
end
