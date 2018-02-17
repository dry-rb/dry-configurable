require 'dry-struct'
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

    class Config < Dry::Struct
      class << self
        private :attribute

        def setting(name, type = nil, &block)
          if block
            attribute(name, Class.new(Config), &block)
          else
            attribute(name, type)
          end
        end
      end
    end

    def self.extended(klass)
      klass.class_eval do
        @finalized = false
        @configured = false
      end
    end

    def setting(name, type = nil, &block)
      raise_already_defined_config(name) if defined?(@config)
      struct_class.setting(name, type, &block)
      define_reader_method(name, type) if type
    end

    def configure
      raise_frozen_config if finalized?
      yield(null_config)
    end

    def null_config
      @null_config ||= NullConfig.from(struct_class)
    end

    def config
      if defined?(@config)
        @config
      else
        struct_class.new(build_default_keys(struct_class))
      end
    rescue Dry::Struct::Error => e
      raise NotConfiguredError,
        "You need to use #configure method to setup values for your configuration, there are some values missing\n" +
        "#{e.message}"
    end

    def finalize!
      @config = struct_class.new(null_config.to_config)
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
    def build_default_keys(settings, start = {})
      settings.attribute_names.each do |key|
        type = settings.schema[key]
        start[key] = {} unless type.default?
        if type.respond_to?(:schema)
          build_default_keys(type, start[key])
        end
      end
      start
    end

    # @private
    def struct_class
      @struct_class ||= Class.new(Config)
    end
  end
end
