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
    NotConfiguredError  = Class.new(StandardError)
    AlreadyDefinedConfigError = Class.new(StandardError)

    class ProxySettings
      attr_reader :schema

      def initialize(settings, &block)
        @settings = settings
        @schema = {}
        instance_eval(&block)
      end

      def config(key, value = nil, &block)
        if settings.attribute?(key)
          value = block ? self.class.new(settings.schema[key], &block).schema : value
          schema[key] = value
        end
      end

      private
      attr_reader :settings
    end

    class StructBuilder
      attr_reader :struct_class

      def initialize(&block)
        @struct_class = Class.new(Dry::Struct)
        instance_eval(&block)
      end

      def setting(name, type = nil, &block)
        if block
          type = self.class.new(&block).struct_class
        end
        struct_class.attribute(name, type)
      end
    end

    def self.extended(base)
      base.class_eval do
        @settings = Class.new(Dry::Struct)
        @reader_options = []
      end
    end

    def setting(name, type = nil, &block)
      raise_already_defined_config(name) if defined?(@config)
      if block
        type = build_struct(&block)
      end
      @settings.attribute(name, type)
      store_reader_key(name) if reader_options?(@settings)
    end

    def build_struct(&block)
      StructBuilder.new(&block).struct_class
    end

    def configure(&block)
      settings_values = ProxySettings.new(@settings, &block).schema
      @config = @settings.new(settings_values)
      self
    end

    def config
      if defined?(@config)
        @config
      else
        @settings.new(build_default_keys(@settings))
      end
    rescue Dry::Struct::Error => e
      raise NotConfiguredError,
        "You need to use #configure method to setup values for your configuration, there are some values missing\n" +
        "#{e.message}"
    end

    # @private
    def raise_already_defined_config(key)
      raise AlreadyDefinedConfigError,
            "Cannot add setting +#{name}+, #{self} is already configured"
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
    def method_missing(method, *args, &block)
      @reader_options.include?(method) ? config.public_send(method, *args, &block) : super
    end

    # @private
    def store_reader_key(key)
      @reader_options << key
    end

    # @private
    def reader_options?(settings)
      types = extract_types(settings)
      types.any? { |type| type.meta[:reader] }
    end

    # @private
    def extract_types(settings)
      settings.attribute_names.each_with_object([]) do |key, acc|
        type = settings.schema[key]
        if type.respond_to?(:schema)
          acc << extract_types(type)
        else
          acc << type
        end
      end.flatten
    end
  end
end
