require 'concurrent/array'
require 'dry/core/constants'
require 'dry/configurable/config'
require 'dry/configurable/error'
require 'dry/configurable/nested_config'
require 'dry/configurable/argument_parser'
require 'dry/configurable/config/value'
require 'dry/configurable/version'

# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
module Dry
  # A simple configuration mixin
  #
  # @example
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
  #     # => "jdbc:sqlite:memory'"
  #
  # @api public
  module Configurable
    include Dry::Core::Constants

    module ClassInterface
      Parser = ArgumentParser.new.freeze

      # Add a setting to the configuration
      #
      # @param [Mixed] key
      #   The accessor key for the configuration value
      # @param [Mixed] default
      #   The default config value
      #
      # @yield
      #   If a block is given, it will be evaluated in the context of
      #   and new configuration class, and bound as the default value
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def setting(key, value = Undefined, options = Undefined, &block)
        extended = singleton_class < Configurable
        raise_already_defined_config(key) if extended && configured?

        value, options, processor = Parser.(value, options, block)

        _settings << Config::Value.new(key, value, processor)

        if options[:reader]
          readers = extended ? singleton_class : self
          readers.define_method(key) { config.public_send(key) }
        end
      end

      # Return an array of setting names
      #
      # @return [Array]
      #
      # @api public
      def settings
        _settings.map(&:name)
      end

      # @private
      def nested_configs
        _settings.select { |setting| setting.value.is_a?(::Dry::Configurable::NestedConfig) }.map(&:value)
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
      def _config_for(&block)
        ::Dry::Configurable::NestedConfig.new(&block)
      end

      # @private
      def self.extended(base)
        base.class_eval do
          @settings = ::Concurrent::Array.new
        end
      end
    end

    # @private
    def self.extended(base)
      base.class_eval do
        @config_mutex = ::Mutex.new
      end
      base.extend(ClassInterface)
    end

    # @private
    def self.included(base)
      base.extend(ClassInterface)
    end

    def initialize
      @config_mutex = ::Mutex.new
    end

    # @private
    def inherited(subclass)
      subclass.instance_variable_set(:@config_mutex, ::Mutex.new)
      subclass.instance_variable_set(:@settings, @settings.clone)
      subclass.instance_variable_set(:@config, @config.clone) if defined?(@config)
      super
    end

    # Return configuration
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def config
      return @config if defined?(@config)
      create_config
    end

    # Return configuration
    #
    # @yield [Dry::Configuration::Config]
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def configure
      raise_frozen_config if frozen?
      yield(config)
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

    def configured?
      defined?(@config)
    end

    private

    # @private
    def create_config
      @config_mutex.synchronize do
        unless _settings.empty?
          break @config if defined? @config
          @config = ::Dry::Configurable::Config.create(_settings)
        end
      end
    end

    def _settings
      self.class._settings
    end

    # @private
    def raise_frozen_config
      raise FrozenConfig, 'Cannot modify frozen config'
    end
  end
end
