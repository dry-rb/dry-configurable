require 'concurrent'
require 'dry/configurable/config'
require 'dry/configurable/config/value'
require 'dry/configurable/version'

# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
module Dry
  # @private
  SETTING_OPTIONS = {
    processor: ::Dry::Configurable::Config::DEFAULT_PROCESSOR
  }.freeze

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
      @_config_mutex.synchronize do
        @_config ||= ::Dry::Configurable::Config.create(_settings) unless _settings.empty?
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
    #   The default config value (optional)
    # @param [Hash] options
    # @option options [Symbol] :processor
    #   An optional proc used to preprocess the config value when set
    #
    # @yield
    #   If a block is given, it will be evaluated in the context of
    #   and new configuration class, and bound as the default value
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def setting(key, *args, &block)
      value, options = process_setting_args(args)

      _settings << ::Dry::Configurable::Config::Value.new(
        key,
        block ? _config_for(&block) : value,
        options.fetch(:processor, ::Dry::Configurable::Config::DEFAULT_PROCESSOR)
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
      config_klass = ::Class.new { extend ::Dry::Configurable }
      config_klass.instance_eval(&block)
      config_klass.config
    end

    # @private
    def process_setting_args(args)
      case args.length
      when 0
        [::Dry::Configurable::Config::Value::NONE, {}]
      when 1
        value = args.first

        if args.first.is_a?(::Hash)
          options = SETTING_OPTIONS.each_with_object({}) do |tuple, hash|
            hash[tuple.first] = value.delete(tuple.first) || tuple.last
          end

          if value.keys.length > 0
            [value, options]
          else
            [::Dry::Configurable::Config::Value::NONE, options]
          end
        else
          [args.first, {}]
        end
      else
        args
      end
    end
  end
end
