require 'concurrent'
require 'dry/configurable/config'
require 'dry/configurable/error'
require 'dry/configurable/nested_config'
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
  #   App.configure do |config|
  #     config.database.dsn = 'jdbc:sqlite:memory'
  #   end
  #
  #   App.config.database.dsn
  #     # => "jdbc:sqlite:memory'"
  #
  # @api public
  module Configurable
    # @private
    def self.extended(base)
      base.class_eval do
        @_config_mutex = ::Mutex.new
        @_settings = ::Concurrent::Array.new
      end
    end

    # @private
    def inherited(subclass)
      subclass.instance_variable_set(:@_config_mutex, ::Mutex.new)
      subclass.instance_variable_set(:@_settings, @_settings.clone)
      subclass.instance_variable_set(:@_config, @_config.clone) if defined?(@_config)
      super
    end

    # Return configuration
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def config
      return @_config if defined?(@_config)
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
      yield(config) if block_given?
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
    #   and new configuration class, and bound as the default value
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def setting(key, value = ::Dry::Configurable::Config::Value::NONE, &block)
      raise_already_defined_config(key) if defined?(@_config)
      if block
        if block.parameters.empty?
          value = _config_for(&block)
        else
          processor = block
        end
      end

      _settings << ::Dry::Configurable::Config::Value.new(
        key,
        value,
        processor || ::Dry::Configurable::Config::DEFAULT_PROCESSOR
      )
    end

    # Return an array of setting names
    #
    # @return [Array]
    #
    # @api public
    def settings
      _settings.map(&:name)
    end

    # @private no, really...
    def _settings
      @_settings
    end

    private

    # @private
    def _config_for(&block)
      ::Dry::Configurable::NestedConfig.new(&block)
    end

    # @private
    def create_config
      @_config_mutex.synchronize do
        create_config_for_nested_configurations
        @_config = ::Dry::Configurable::Config.create(_settings) unless _settings.empty?
      end
    end

    # @private
    def create_config_for_nested_configurations
      nested_configs.map {  |nested_config| nested_config.create_config }
    end

    # @private
    def nested_configs
      _settings.select { |setting| setting.value.kind_of?(::Dry::Configurable::NestedConfig) }.map(&:value)
    end

    # @private
    def raise_already_defined_config(key)
      raise AlreadyDefinedConfig,
        "Cannot add setting +#{key}+, #{self} is already configured"
    end
  end
end
