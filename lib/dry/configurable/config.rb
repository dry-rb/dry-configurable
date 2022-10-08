# frozen_string_literal: true

require "dry/core/constants"

module Dry
  module Configurable
    # Config exposes setting values through a convenient API
    #
    # @api public
    class Config
      include Dry::Equalizer(:values)

      # @api private
      attr_reader :_settings

      # @api private
      attr_reader :_superconfig

      # @api private
      attr_reader :_values

      # @api private
      def initialize(settings, values: {}, superconfig: nil)
        @_settings = settings
        @_values = values
        @_superconfig = superconfig
      end

      # @api private
      def dup_for_settings(settings)
        self.class.new(settings, superconfig: self)
      end

      # Get config value by a key
      #
      # @param [String,Symbol] name
      #
      # @return Config value
      def [](name)
        name = name.to_sym

        unless (setting = _settings[name])
          raise ArgumentError, "+#{name}+ is not a setting name"
        end

        _values.fetch(name) {
          value = _superconfig&.[](name) if _superconfig&._settings&.key?(name)
          value = value.dup if value && setting.cloneable?
          value ||= setting.to_value

          _values[name] = value if setting.cloneable?

          value
        }
      end

      # Set config value.
      # Note that finalized configs cannot be changed.
      #
      # @param [String,Symbol] name
      # @param [Object] value
      def []=(name, value)
        raise FrozenConfig, "Cannot modify frozen config" if frozen?

        name = name.to_sym

        unless (setting = _settings[name])
          raise ArgumentError, "+#{name}+ is not a setting name"
        end

        _values[name] = setting.constructor.(value)
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

      def key?(key)
        _values.key?(key)
      end

      # Returns true if the value for the given key has been set on this config.
      #
      # For simple values, this returns true if the value has been explicitly assigned.
      #
      # For cloneable (mutable) values, since these are captured on read, returns true if the value
      # does not compare equally to its corresdponing default value. This relies on these objects
      # having functioning `#==` checks.
      #
      # @return [Bool]
      #
      # @api public
      def configured?(key)
        if _settings[key].cloneable? && _values.key?(key)
          return _values[key] != _settings[key].to_value
        end

        _values.key?(key) || !!_superconfig&.configured?(key)
      end

      # Returns the current config values.
      #
      # Nested configs remain in their {Config} instances.
      #
      # @return [Hash]
      #
      # @api public
      def values
        _settings.to_h { |setting| [setting.name, self[setting.name]] }
      end

      # Returns config values as a hash, with nested values also converted from {Config} instances
      # into hashes.
      #
      # @return [Hash]
      #
      # @api public
      def to_h
        values.to_h { |key, value| [key, value.is_a?(self.class) ? value.to_h : value] }
      end

      # @api private
      def finalize!(freeze_values: false)
        values.each_value do |value|
          if value.is_a?(self.class)
            value.finalize!(freeze_values: freeze_values)
          elsif freeze_values
            value.freeze
          end
        end

        freeze
      end

      # @api private
      def pristine
        self.class.new(_settings)
      end

      private

      def method_missing(name, *args)
        setting_name = setting_name_from_method(name)
        setting = _settings[setting_name]

        super unless setting

        if name.end_with?("=")
          self[setting_name] = args[0]
        else
          self[setting_name]
        end
      end

      def respond_to_missing?(meth, include_private = false)
        _settings.key?(setting_name_from_method(meth)) || super
      end

      def setting_name_from_method(method_name)
        method_name.to_s.tr("=", "").to_sym
      end

      def dup_values
        _values.each_with_object({}) { |(key, val), dup_hsh|
          dup_hsh[key] = _settings[key].cloneable? ? val.dup : val
        }
      end

      def initialize_copy(source)
        super
        @_values = source.__send__(:dup_values)
      end
    end
  end
end
