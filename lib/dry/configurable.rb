require 'concurrent'
require 'dry/configurable/config'
require 'dry/configurable/config/value/lazy'
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
        @_settings = ::Concurrent::Hash.new
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
      @_config_mutex.synchronize do
        @_config ||= ::Dry::Configurable::Config.new(_settings) unless _settings.empty?
      end
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
    def setting(key, default = nil, &block)
      if block
        if block.arity.zero?
          _settings[key] = _config_for(&block)
        else
          _settings[key] = ::Dry::Configurable::Config::Value::Lazy.new(
            block
          )
        end
      else
        _settings[key] = default
      end
    end

    # @private no, really...
    def _settings
      @_settings
    end

    private

    # @private
    def _config_for(&block)
      config_klass = ::Class.new { extend ::Dry::Configurable }
      config_klass.instance_eval(&block)
      config_klass.config
    end
  end
end
