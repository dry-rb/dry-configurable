require 'dry-struct'
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
  #   App.configure do
  #     config :database_url, 'jdbc:sqlite:memory'
  #   end
  #
  #   App.config.database_url
  #     # => "jdbc:sqlite:memory'"
  #
  # @api public
  module Configurable
    NotConfiguredError  = Class.new(StandardError)
    AlreadyDefinedConfigError = Class.new(StandardError)
    FrozenConfigError = Class.new(StandardError)

    def self.extended(klass)
      klass.class_eval do
        @finalized = false
      end
    end

    def setting(name, type = nil, &block)
      raise_already_defined_config(name) if defined?(@config)
      set_setting(name, type, &block)
      define_reader_method(name, type) if type
    end

    def configure
      raise_frozen_config if finalized?
      yield(null_config_instance)
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
        struct_class.new
      end
    rescue Dry::Struct::Error => e
      raise NotConfiguredError,
        "You need to use #configure method to setup values for your configuration, there are some values missing\n" +
        "#{e.message}"
    end

    def finalize!
      @config = struct_class.new(null_config_instance.attributes)
      @finalized = true
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
    def finalized?
      @finalized
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
