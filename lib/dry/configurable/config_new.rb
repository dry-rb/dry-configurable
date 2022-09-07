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
        # @attributes = source.instance_variable_get(:@attributes).dup
        @attributes = source.values.map { |k, v| [k, v.dup] }.to_h
      end

      def [](name)
        raise ArgumentError, "+#{name}+ is not a setting name" unless self.class.keys.include?(name)

        # FIXME: this has to go through the generated reader to work... which doesn't feel right, and WON'T work for attributes with conflicting names
        public_send(name)
        # @attributes[name]
      end

      def []=(name, value)
        raise ArgumentError, "+#{name}+ is not a setting name" unless self.class.keys.include?(name)

        public_send(:"#{name}=", value)
      end

      def update(values)
        values.each do |key, value|
          if self[key].is_a?(ConfigNew)
            unless value.respond_to?(:to_hash)
              raise ArgumentError, "#{value.inspect} is not a valid setting value"
            end

            self[key].update(value.to_hash)
          else
            self[key] = value
          end
        end
        self
      end

      # def values
      #   @attributes.to_h
      # end

      def values
        # _settings
        #   .map { |setting| [setting.name, setting.value] }
        #   .map { |key, value| [key, value.is_a?(self.class) ? value.to_h : value] }
        #   .to_h

        # TODO: only do this once?
        self.class.keys.each { |setting_name|
          self[setting_name]
        }
        @attributes
      end
      alias_method :to_h, :values

      def finalize!(freeze_values: false)
        values.each_value do |value|
          if value.is_a?(ConfigNew) # can't use self.class here anymore
            value.finalize!(freeze_values: freeze_values)
          elsif freeze_values
            value.freeze
          end
        end

        freeze
      end

      def pristine
        self.class.new
      end
    end
  end
end
