# frozen_string_literal: true

require "concurrent/map"

module Dry
  module Configurable
    # A settings map
    #
    # @api private

    # This would actually better be called "Config" in the structure I'm trying here
    class Settings

      DEFAULT_CONSTRUCTOR = :itself.to_proc.freeze

      # include Dry::Equalizer(:elements)

      # include Enumerable

      def self.setting_names
        @setting_names ||= []
      end

      def self.nested_settings
        @nested_settings ||= {}
      end

      # Options:
      #
      # default
      # reader
      # constructor
      # cloneable
      #
      # children??

      def self.define_setting(name, **options)
        setting_names << name

        constructor = options[:constructor] || DEFAULT_CONSTRUCTOR

        default_value = constructor.call(
          Dry::Core::Constants::Undefined.coalesce(options[:default], nil)
        )

        define_method(name) do
          if instance_variable_defined?(:"@#{name}")
            instance_variable_get(:"@#{name}")
          else
            # TODO: should actually be set in #initialize somehow?
            # Or should this instance_variable_set?

            # default_value

            instance_variable_set(:"@#{name}", default_value)
          end
        end

        define_method("#{name}=") do |value|
          instance_variable_set(:"@#{name}", constructor.call(value))
        end
      end

      def self.define_nested(name, klass)
        nested_settings[name] = klass
      end

      # def self.define_nested(name)
      #   define_method(name) do
      #     if instance_variable_defined?(:"@#{name}")
      #       instance_variable_get(:"@#{name}")
      #     else
      #       instance_variable_set(:"@#{name}", nested_class.new)
      #     end
      #   end
      # end

      # def self.define_nested(name)
      #   nested_class = Class.new(Settings)

      #   define_method(name) do
      #     if instance_variable_defined?(:"@#{name}")
      #       instance_variable_get(:"@#{name}")
      #     else
      #       instance_variable_set(:"@#{name}", nested_class.new)
      #     end
      #   end
      # end

      # What would nested look like?

      def database
        @database = Settings.new
      end


      # # @api private
      # attr_reader :elements

      # # @api private
      # def initialize(elements = EMPTY_ARRAY)
      #   initialize_elements(elements)
      # end

      # @api private
      # def <<(setting)
      #   elements[setting.name] = setting
      #   self
      # end

      # @api private
      # def [](name)
      #   elements[name]
      # end

      # @api private
      # def key?(name)
      #   keys.include?(name)
      # end

      # @api private
      # def keys
      #   elements.keys
      # end

      # @api private
      # def each(&block)
      #   elements.values.each(&block)
      # end
    end
  end
end
