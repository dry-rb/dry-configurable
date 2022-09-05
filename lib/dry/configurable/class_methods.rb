# frozen_string_literal: true

require "set"

module Dry
  module Configurable
    module ClassMethods
      include Methods

      # @api private
      def inherited(subclass)
        super

        # subclass.instance_variable_set("@_settings", _settings) #.dup)



        # wtf is `respond_to` actually doing here?
        subclass.instance_variable_set("@config", config.dup) if respond_to?(:config)
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
      # def settings
      #   Set[*_settings.map(&:name)]
      # end
      def settings
        # WIP: be rspec spec/integration/dry/configurable/setting_spec.rb:283
        # WIP: stuck on inheritance - how do make it so the settings (settings mods) are inherited?

        # Set[*_settings.keys]

        # WIP: OK, this should _probably_ work off config class
        #
        # Though it might be better if we could refer to `config.class` internally here as `settings`
        Set[*config.class.keys]
      end

      # Return declared settings
      #
      # @return [Settings]
      #
      # @api public
      def _settings
        @_settings ||= SettingsNew.new.tap do |settings_mod|
          config_class.extend_settings(settings_mod)
        end
      end

      def config_class
        @config_class ||= Class.new(ConfigNew)
      end

      # Return configuration
      #
      # @return [Config]
      #
      # @api public
      def config
        @config ||= config_class.new
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
