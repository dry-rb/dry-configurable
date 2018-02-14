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

    def setting(name, type = nil, &block)
      raise_already_defined_config(name) if defined?(@config)
      raise(
        'You can only pass a type or a block'
      ) if type && block

      struct_class.setting(name, type, &block)
      store_reader_key(name) if reader_options?
    end

    def configure
      yield(null_config)
      finalize! unless finalized?
    end

    def null_config
      @null_config ||= NullConfig.new
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

    private

    # @private
    def raise_already_defined_config(key)
      raise AlreadyDefinedConfigError,
            "Cannot add setting +#{name}+, #{self} is already configured"
    end

    # @private
    def finalize!
      @config = struct_class.new(null_config.to_config)
      @finalized = true
    end

    # @private
    def finalized?
      @finalized == true
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
      reader_options.include?(method) ? config.public_send(method, *args, &block) : super
    end

    # @private
    def struct_class
      @struct_class ||= Class.new(Config)
    end

    # @private
    def store_reader_key(key)
      reader_options << key
    end

    # @private
    def reader_options?
      types = extract_types(struct_class)
      types.any? { |type| type.meta[:reader] }
    end

    # @private
    def extract_types(struct_class)
      struct_class.attribute_names.each_with_object([]) do |key, acc|
        type = struct_class.schema[key]
        if type.respond_to?(:schema)
          acc << extract_types(type)
        else
          acc << type
        end
      end.flatten
    end

    # @private
    def reader_options
      @reader_options ||= []
    end
  end
end
