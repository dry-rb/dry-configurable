# frozen_string_literal: true

require "set"

module Dry
  module Configurable
    module ClassMethods
      include Methods

      # @api private
      def inherited(subclass)
        super

        subclass.instance_variable_set(:@__config_extension__, __config_extension__)

        # Share settings with subclasses until they define their own additional settings (see
        # `.setting` below).
        subclass.instance_variable_set(:@_settings, _settings)

        # Only classes that **extend** Dry::Configurable have class-level `config`. When a class
        # **includes** Dry::Configurable, the class-level `config` method is undefined because it
        # resides at the instance-level instead (see `Configurable.included`).
        if respond_to?(:config)
          subclass.instance_variable_set(:@config, config.dup)
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

        # If we're sharing settings with our superclass, create our own copy (along with a matching
        # config copy) at the time of first new setting definition.
        if superclass.respond_to?(:_settings) && _settings.eql?(superclass._settings)
          @_settings = _settings.dup_for_child
          @config = config.dup_for_settings(_settings) if respond_to?(:config)
        end

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
        @_settings ||= Settings.new
      end

      # Return configuration
      #
      # @return [Config]
      #
      # @api public
      def config
        @config ||= __config_build__
      end

      # @api private
      def __config_build__(settings = _settings)
        __config_extension__.config_class.new(settings)
      end

      # @api private
      def __config_extension__
        @__config_extension__
      end

      # @api private
      def __config_dsl__
        @__config_dsl__ ||= DSL.new(
          config_class: __config_extension__.config_class,
          default_undefined: __config_extension__.default_undefined
        )
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
