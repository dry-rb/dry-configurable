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
      attr_reader :_values

      # @api private
      def initialize(settings, values: {})
        @_settings = settings
        @_values = values
      end

      # @api private
      def dup_for_settings(settings)
        # Orig
        # self.class.new(settings, values: dup_values)

        # New
        # self.class.new(settings, values: _values)

        # Xtreme
        self
      end

      # def dup_for_update
      #   self.class.new(settings, values: _values.dup)
      # end

      def for_update
        UpdatingConfig.new(self)
      end

      class UpdatingConfig
        attr_reader :config
        attr_reader :updated_values

        def initialize(config)
          @config = config
          @updated_values = {}
        end

        def [](name)
          updated_values[name] = config[name].dup
        end

        # TODO: It would be good if I didn't have to copy this whole implementation
        def []=(name, value)
          name = name.to_sym
          raise ArgumentError, "+#{name}+ is not a setting name" unless (setting = _settings[name])

          updated_values[name] = setting.constructor.(value)
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

      def to_update
        # Raise argument error if no block

        updated = for_update
        yield(updated)

        @_values = _values.dup

        updated.updated_values.each do |key, val|
          @_values[key] = val
        end

        @_values.freeze

        self
      end

      # Get config value by a key
      #
      # @param [String,Symbol] name
      #
      # @return Config value
      def [](name)
        name = name.to_sym
        raise ArgumentError, "+#{name}+ is not a setting name" unless (setting = _settings[name])

        _values.fetch(name) { _values[name] = setting.to_value }
      end

      # Set config value.
      # Note that finalized configs cannot be changed.
      #
      # @param [String,Symbol] name
      # @param [Object] value
      def []=(name, value)
        raise FrozenConfig, "Cannot modify frozen config" if frozen?

        name = name.to_sym
        raise ArgumentError, "+#{name}+ is not a setting name" unless (setting = _settings[name])

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

      # Dump config into a hash
      #
      # @return [Hash]
      #
      # @api public
      def values
        # Ensure all settings are represented in values
        _settings.each { |setting| self[setting.name] unless _values.key?(setting.name) }

        _values
      end
      alias_method :to_h, :values

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
        @_values = source.send(:dup_values)
      end
    end
  end
end
