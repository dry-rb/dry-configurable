# frozen_string_literal: true

require "set"

module Dry
  module Configurable
    module ClassMethods
      include Methods

      # @api private
      def inherited(subclass)
        super

        new_settings = _settings.dup

        subclass.instance_variable_set("@_settings", new_settings)

        # Only classes extending (as opposed to including) Dry::Configurable have class-level config
        if respond_to?(:config)
          subclass.instance_variable_set("@config", config.dup_for_settings(new_settings))
        end
      end

      # Add a setting to the configuration
      #
      # @param [Mixed] name
      #   The accessor key for the configuration value
      # @param [Mixed] default
      #   Default value for the setting
      # @param [#call] constructor
      #   Transformation given value will go through
      # @param [Boolean] reader
      #   Whether a reader accessor must be created
      # @yield
      #   A block can be given to add nested settings.
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def setting(*args, **options, &block)
        setting = __config_dsl__.setting(*args, **options, &block)

        # "copy on write"
        # unless _settings.target.eql?(self)
        #   @_settings = _settings.copy_for_target(self)
        #   @config = config.copy_for_settings(_settings)
        # end

        _settings << setting

        __config_reader__.define(setting.name) if setting.reader?

        self
      end

      # Return declared settings
      #
      # @return [Set<Symbol>]
      #
      # @api public
      def settings
        Set[*_settings.map(&:name)]
      end

      # Return declared settings
      #
      # @return [Settings]
      #
      # @api public
      def _settings
        @_settings ||= Settings.new(target: self)
      end

      # Return configuration
      #
      # @return [Config]
      #
      # @api public
      def config
        # The _settings provided to the Config remain shared between the class and the
        # Config. This allows settings defined _after_ accessing the config to become
        # available in subsequent accesses to the config. The config is duped when
        # subclassing to ensure it remains distinct between subclasses and parent classes
        # (see `.inherited` above).
        @config ||= Config.new(_settings)
      end

      # @api private
      def __config_dsl__
        @__config_dsl__ ||= DSL.new
      end

      # @api private
      def __config_reader__
        @__config_reader__ ||=
          begin
            reader = Module.new do
              def self.define(name)
                define_method(name) do
                  config[name]
                end
              end
            end

            if included_modules.include?(InstanceMethods)
              include(reader)
            end

            extend(reader)

            reader
          end
      end
    end
  end
end
