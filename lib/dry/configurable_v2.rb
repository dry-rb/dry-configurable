require 'dry-struct'
# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby

module Dry
  # A simple configuration mixin
  #
  # @example
  #
  #   class App
  #     extend Dry::ConfigurableV2
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
  module ConfigurableV2
    NotConfigured  = Class.new(StandardError)
    AlreadyDefinedConfig = Class.new(StandardError)

    class ProxySettings
      attr_reader :schema

      def initialize(settings, processors, &block)
        @settings = settings
        @processors = processors
        @schema = {}
        instance_eval(&block)
      end

      def config(key, value = nil, &block)
        if settings.attribute?(key)
          value = if block
                    self.class.new(settings.schema[key], processors, &block).schema
                  else
                    processors.key?(key) ? processors[key].call(value) : value
                  end
          schema[key] = value
        end
      end

      private
      attr_reader :processors, :settings
    end

    class StructBuilder
      def initialize(processors, &block)
        @processors = processors
        instance_eval(&block)
      end

      def setting(name, type, &block)
        if block && block.parameters.any?
          processors[name] = block
        end
        struct_class.attribute(name, type)
      end

      def struct_class
        @struct_class ||= Class.new(Dry::Struct)
      end

      private
      attr_reader :processors
    end

    def self.extended(base)
      base.class_eval do
        @settings = Class.new(Dry::Struct)
        @processors = ::Concurrent::Hash.new
      end
    end

    def setting(name, type = nil, &block)
      raise_already_defined_config(name) if defined?(@config)
      if block
        if block.parameters.any?
          @processors[name] = block
        else
          type = build_struct(&block)
        end
      end
      @settings.attribute(name, type)
    end

    def build_struct(&block)
      StructBuilder.new(@processors, &block).struct_class
    end

    def configure(&block)
      settings_values = ProxySettings.new(@settings, @processors, &block).schema
      @config = @settings.new(settings_values)
      self
    end

    def config
      if defined?(@config)
        @config
      else
        @settings.new
      end
    rescue Dry::Struct::Error => e
      raise NotConfigured,
        "You need to use #configure method to setup values for your configuration, there are some values missing\n" +
        "#{e.message}"
    end

    # @private
    def raise_already_defined_config(key)
      raise AlreadyDefinedConfig,
            "Cannot add setting +#{name}+, #{self} is already configured"
    end
  end
end
