require 'dry-struct'
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
        @configured = false
      end
    end

    def inherited(subclass)
      subclass.instance_variable_set(:@configured, @configured)
      subclass.instance_variable_set(:@null_config, @null_config.clone) if defined?(@null_config)
      subclass.instance_variable_set(:@null_config_instance, @null_config_instance.clone) if defined?(@null_config_instance)
      subclass.instance_variable_set(:@struct_class, @struct_class.clone) if defined?(@struct_class)
      subclass.instance_variable_set(:@config, @config.clone) if defined?(@config)
      super
    end


    def setting(name, type = nil, &block)
      raise_already_defined_config(name) if defined?(@config)
      set_setting(name, type, &block)
      define_reader_method(name, type) if type
    end

    def configure
      raise_frozen_config if frozen?
      yield(null_config_instance)
      @configured = true
    end

    def null_config
      @null_config ||= Class.new(NullConfig)
    end

    def null_config_instance
      @null_config_instance ||= null_config.new
    end

    def config
      if defined?(@config)
        @config
      else
        create_config
      end
    rescue Dry::Struct::Error => e
      raise NotConfiguredError,
        "You need to use #configure method to setup values for your configuration, there are some values missing\n" +
        "#{e.message}"
    end

    def finalize!
      freeze
    end

    private

    def define_reader_method(name, type)
      singleton_class.class_eval do
        define_method(name) do
          config.public_send(name)
        end
      end if reader_option?(type)
    end

    def reader_option?(type)
      type.meta.fetch(:reader) { false }
    end

    # @private
    def raise_already_defined_config(key)
      raise AlreadyDefinedConfigError,
            "Cannot add setting +#{name}+, #{self} is already configured"
    end

    # @private
    def raise_frozen_config
      raise FrozenConfigError, 'Cannot modify frozen config'
    end

    # @private
    def create_config
      @config = @configured ? struct_class.new(null_config_instance.attributes) : struct_class.new
    end

    # @private
    def struct_class
      @struct_class ||= Class.new(Config)
    end

    def set_setting(name, type, &block)
      struct_class.setting(name, type, &block)
      null_config.setting(name, type, &block)
    end
  end
end
