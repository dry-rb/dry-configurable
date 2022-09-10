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

      attr_reader :_values

      # @api private
      def initialize(settings, values: {})
        @_settings = settings
        @_values = values
      end

      def dup_for_settings(settings)
        self.class.new(
          settings,
          values: values.map { |k, v| [k, v.dup] }.to_h, # TODO: this should only dup the cloneable values
        )
      end

      def copy_for_settings(new_settings)
        self.class.new(new_settings, values: @_values)
      end

      # Get config value by a key
      #
      # @param [String,Symbol] name
      #
      # @return Config value
      # def [](name)
      #   name = name.to_sym
      #   raise ArgumentError, "+#{name}+ is not a setting name" unless _settings.key?(name)

      #   _settings[name].value
      # end

      # WIP
      def [](name)
        name = name.to_sym
        raise ArgumentError, "+#{name}+ is not a setting name" unless _settings.key?(name)

        _values.fetch(name) {
          setting = _settings[name]

          _values[name] =
            if setting.children
              self.class.new(setting.children)
            else
              setting.to_value
            end
        }
      end

      # Set config value.
      # Note that finalized configs cannot be changed.
      #
      # @param [String,Symbol] name
      # @param [Object] value
      def []=(name, value)
        public_send(:"#{name}=", value)
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
        # _settings
        #   .map { |setting| [setting.name, setting.value] }
        #   .map { |key, value| [key, value.is_a?(self.class) ? value.to_h : value] }
        #   .to_h

        # TODO: only do this once?
        _settings.each { |setting|
          self[setting.name]
        }
        _values
      end
      alias_method :to_h, :values

      # @api private
      def finalize!(freeze_values: false)
        # FIXME: probably can't be doing this if we're sharing setting definitions
        # _settings.finalize!(freeze_values: freeze_values)

        # TODO
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
      # TODO: Do I need this????
      def pristine
        # self.class.new(_settings.pristine)
        self.class.new(_settings)
      end

      # @api private
      def respond_to_missing?(meth, include_private = false)
        _settings.key?(setting_name_from_method(meth)) || super
      end

      private

      # @api private
      def method_missing(name, *args)
        setting_name = setting_name_from_method(name)
        setting = _settings[setting_name]

        super unless setting

        if setting.writer?(name)
          raise FrozenConfig, "Cannot modify frozen config" if frozen?

          # _settings << setting.with(input: args[0])
          _values[setting_name] = setting.constructor.(args[0])
        else
          # setting.value
          self[setting_name]
        end
      end

      # @api private
      def setting_name_from_method(method_name)
        method_name.to_s.tr("=", "").to_sym
      end

      # @api private
      def initialize_copy(source)
        super

        # TODO: FIXME: I don't think we want to do this anymore for the CoW approach
        @_settings = source._settings #.dup

        # @_values = source._values.dup
        # ^ _values or values, i.e. do we want to fully resolve values? I think _probably_ not, but double check
        # byebug
        # @_values = source._values.map { |k, v| [k, v.dup] }.to_h

        # Yeah, I think we want to fully resolve it
        @_values = source.values.map { |k, v| [k, v.dup] }.to_h
      end
    end
  end
end
