# frozen_string_literal: true

module Dry
  module Configurable
    class ConfigNew
      class << self
        def extend_settings(settings_module)
          settings_modules << settings_module
          extend(settings_module)
        end

        def settings_modules
          @settings_modules ||= []
        end

        def keys
          settings_modules.map(&:keys).reduce([], :+)
        end

        # def settings
        #   # TODO: Concurrent::Map?
        #   @settings ||= {}
        # end

        # def add_settings(new_settings)
        #   new_settings.each do |setting|
        #     settings[setting.name] = setting
        #   end
        # end
        # def self.settings
      end

      def initialize(attributes = {})
        @attributes = attributes
      end

      def initialize_copy(source)
        @attributes = source.instance_variable_get(:@attributes).dup
      end

      def [](name)
        @attributes[name]
      end

      def values
        @attributes.to_h
      end
    end
  end
end
