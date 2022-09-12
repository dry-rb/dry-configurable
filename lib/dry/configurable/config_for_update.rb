# frozen_string_literal: true

require "dry/core/constants"

module Dry
  module Configurable
    # @api private
    class ConfigForUpdate
      attr_reader :config
      attr_reader :updated_values

      def initialize(config)
        @config = config
        @updated_values = {}
      end

      # @api public
      def [](name)
        updated_values.fetch(name) {
          updated_values[name] =
            config[name].is_a?(Config) ? config[name].for_update : config[name].dup
        }
      end

      # @api public
      def []=(name, value)
        name = name.to_sym
        raise ArgumentError, "+#{name}+ is not a setting name" unless (setting = _settings[name])

        updated_values[name] = setting.constructor.(value)
      end

      # Update config with new values
      #
      # @param values [Hash, #to_hash] A hash with new values
      #
      # @return [Config]
      #
      # @api public
      def update(values)
        values.each do |key, value|
          if self[key].is_a?(self.class)
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

      # @api private
      def to_config
        config.class.new(config._settings, values: config.values.dup).tap do |new_config|
          updated_values.each do |key, val|
            new_config._values[key] = val.is_a?(self.class) ? val.to_config : val
          end
        end
      end

      private

      def method_missing(name, *args)
        return super unless config.respond_to?(name)

        setting_name = setting_name_from_method(name)
        setting = config._settings[setting_name]

        if setting && name.end_with?("=")
          self[setting_name] = args[0]
        elsif setting
          self[setting_name]
        else
          config.public_send(name, *args)
        end
      end

      def respond_to_missing?(name, include_private = false)
        config.respond_to?(name, include_private) || super
      end

      def setting_name_from_method(method_name)
        method_name.to_s.tr("=", "").to_sym
      end
    end
  end
end
