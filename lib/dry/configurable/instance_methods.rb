# frozen_string_literal: true

require "dry/configurable/config"
require "dry/configurable/methods"

module Dry
  module Configurable
    # Initializer method which is prepended when `Dry::Configurable`
    # is included in a class
    #
    # @api private
    module Initializer
      # @api private
      def initialize(*)
        @config = self.class.__config_build__(self.class._settings)
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
        @config = source.config.dup
      end
    end
  end
end
