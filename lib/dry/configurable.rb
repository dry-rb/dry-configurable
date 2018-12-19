require 'dry-struct'
require 'dry/configurable/helpers'
require 'dry/configurable/error'
require 'dry/configurable/config'
require 'dry/configurable/null_config'

module Dry
  # A simple configuration mixin
  #
  # @example
  #
  #   class App
  #     extend Dry::Configurable
  #
  #     setting :database_url, Types::String.constrained(filled: true)
  #     setting :path, Types::Strict::String do |value|
  #       Pathname(value)
  #     end
  #   end
  #
  #   App.configure do |config|
  #     config.database_url = 'jdbc:sqlite:memory'
  #   end
  #
  #   App.config.database_url
  #     # => "jdbc:sqlite:memory'"
  #
  # @api public
  module Configurable
    def self.extended(klass)
      klass.class_eval do
        extend Helpers
        @configured = false
        @config_mutex = ::Mutex.new
      end
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@configured, @configured)
      subclass.instance_variable_set(:@config_mutex, ::Mutex.new)
      subclass.instance_variable_set(:@null_config, @null_config.clone) if defined?(@null_config)
      subclass.instance_variable_set(:@null_config_instance, @null_config_instance.clone) if defined?(@null_config_instance)
      subclass.instance_variable_set(:@struct_class, @struct_class.clone) if defined?(@struct_class)
      subclass.instance_variable_set(:@config, @config.clone) if defined?(@config)
      super
    end

    def condition(name, &block)
      set_condition(name, &block)
    end

    def setting(name, type_or_value = nil, &block)
      raise_already_defined_config(name) if defined?(@config)
      set_setting(name, type_or_value, &block)
      define_reader_method(name, type_or_value) if type?(type_or_value)
    end

    def configure
      raise_frozen_config if frozen?
      thread_safe do
        yield(null_config_instance)
        @configured = true
      end
    end

    def config
      if defined?(@config)
        @config
      else
        thread_safe do
          @config ||= @configured ? struct_class.new(null_config_instance.attributes) : struct_class.new
        end
      end
    rescue Dry::Struct::Error => e
      raise NotConfiguredError,
            "You need to use #configure method to setup values for your configuration, there are some values missing\n" \
            "#{e.message}"
    end

    def finalize!
      config
      freeze
    end

    private

    def null_config
      @null_config ||= Class.new(NullConfig)
    end

    def null_config_instance
      @null_config_instance ||= null_config.new
    end

    def define_reader_method(name, type)
      return unless reader_option?(type)
      singleton_class.class_eval do
        define_method(name) do
          config.public_send(name)
        end
      end
    end

    def reader_option?(type)
      type.meta.fetch(:reader) { false }
    end

    # @private
    def raise_already_defined_config(name)
      raise AlreadyDefinedConfigError,
            "Cannot add setting +#{name}+, #{self} is already configured"
    end

    # @private
    def raise_frozen_config
      raise FrozenConfigError, 'Cannot modify frozen config'
    end

    # @private
    def struct_class
      @struct_class ||= Class.new(Config)
    end

    # @private
    def set_setting(name, type, &block)
      struct_class.setting(name, type, &block)
      null_config.setting(name, type, &block)
    end

    def set_condition(name, &block)
      null_config.condition(name, &block)
    end

    # @private
    def thread_safe
      @config_mutex.synchronize { yield }
    end
  end
end
