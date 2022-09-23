# frozen_string_literal: true

module Dry
  module Configurable
    # Initializer method which is prepended when `Dry::Configurable`
    # is included in a class
    #
    # @api private
    module Initializer
      # @api private
      def initialize(*)
        @config = self.class.__config_build__(self.class._settings).tap { |config|
          config.extend(Config::Mutable)
        }
        @_configured = true

        super
      end
      ruby2_keywords(:initialize) if respond_to?(:ruby2_keywords, true)
    end

    # Instance-level API when `Dry::Configurable` is included in a class
    #
    # @api public
    module InstanceMethods
      include Methods

      # Return object's configuration
      #
      # @return [Config]
      #
      # @api public
      attr_reader :config

      # Finalize the config and freeze the object
      #
      # @api public
      def finalize!(freeze_values: false)
        super
        freeze
      end

      private

      def initialize_copy(source)
        super
        @config = source.config.dup.tap { |config|
          config.extend(Config::Mutable)
        }
      end
    end
  end
end
