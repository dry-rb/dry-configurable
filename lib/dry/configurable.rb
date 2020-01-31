# frozen_string_literal: true

require 'dry/core/constants'
require 'dry/configurable/settings'
require 'dry/configurable/error'
require 'dry/configurable/version'

# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
module Dry
  # A simple configuration mixin
  #
  # @example class-level configuration
  #
  #   class App
  #     extend Dry::Configurable
  #
  #     setting :database do
  #       setting :dsn, 'sqlite:memory'
  #     end
  #   end
  #
  #   App.config.database.dsn = 'jdbc:sqlite:memory'
  #   App.config.database.dsn
  #     # => "jdbc:sqlite:memory"
  #
  # @example instance-level configuration
  #
  #   class App
  #     include Dry::Configurable
  #
  #     setting :database
  #   end
  #
  #   production = App.new
  #   production.config.database = ENV['DATABASE_URL']
  #   production.finalize!
  #
  #   development = App.new
  #   development.config.database = 'jdbc:sqlite:memory'
  #   development.finalize!
  #
  # @api public
  module Configurable
    include Dry::Core::Constants

    module ClassMethods
      # @private
      def self.extended(base)
        base.instance_exec do
          @settings = Settings.new
        end
      end

      # Add a setting to the configuration
      #
      # @param [Mixed] key
      #   The accessor key for the configuration value
      # @param [Mixed] default
      #   The default config value
      #
      # @yield
      #   If a block is given, it will be evaluated in the context of
      #   a new configuration class, and bound as the default value
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def setting(key, value = Undefined, options = Undefined, &block)
        raise_already_defined_config(key) if _settings.config_defined?

        setting = _settings.add(key, value, options, &block)

        if setting.reader?
          readers = singleton_class < Configurable ? singleton_class : self
          readers.send(:define_method, setting.name) { config[setting.name] }
        end
      end

      # Return an array of setting names
      #
      # @return [Set]
      #
      # @api public
      def settings
        _settings.names
      end

      # @private no, really...
      def _settings
        @settings
      end

      private

      # @private
      def raise_already_defined_config(key)
        raise AlreadyDefinedConfig,
              "Cannot add setting +#{key}+, #{self} is already configured"
      end

      # @private
      def inherited(subclass)
        parent = self

        subclass.instance_exec do
          @settings = parent._settings.dup
        end

        if singleton_class < Configurable
          parent_config = @config

          subclass.instance_exec do
            @config = _settings.create_config
            @config.define!(parent_config.to_h) if parent_config.defined?
          end
        end

        super
      end
    end

    class << self
      # @private
      def extended(base)
        base.extend(ClassMethods)
        base.class_eval do
          @config = _settings.create_config
        end
      end

      # @private
      def included(base)
        base.extend(ClassMethods)
      end
    end

    # @private
    def initialize(*)
      @config = self.class._settings.create_config
      super
    end

    # Return configuration
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def config
      return @config if @config.defined?

      @config.define!
    end

    # Return configuration
    #
    # @yield [Dry::Configuration::Config]
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def configure
      raise FrozenConfig, 'Cannot modify frozen config' if frozen?

      yield(config) if block_given?
      self
    end

    # Finalize and freeze configuration
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def finalize!
      freeze
      config.finalize!
    end

    # @api public
    def dup
      super.tap do |copy|
        copy.instance_variable_set(:@config, config.dup)
      end
    end

    # @api public
    def clone
      if frozen?
        super
      else
        super.tap do |copy|
          copy.instance_variable_set(:@config, config.dup)
        end
      end
    end
  end
end
