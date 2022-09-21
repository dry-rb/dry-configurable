# frozen_string_literal: true

require "dry/core/constants"

require "dry/core/equalizer"

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
      def new_for_settings(settings)
        self.class.new(settings, values: _values)
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

        _values.fetch(name) { _values[name] = setting.to_value } # is freeze too extreme here?
      end

      # @api private
      def []=(name, *)
        raise NoMethodError, <<~MSG
          You must assign config values via the object yielded to `configure`, e.g.

            configure do |config|
              config.#{name} = your_value
            end
        MSG
      end

      # @api private
      def update(*)
        raise NoMethodError, <<~MSG
          You must update config via the object yielded to `configure`, e.g.

            configure do |config|
              config.update(your_values)
            end
        MSG
      end

      # Returns the current config values.
      #
      # Nested configs remain in their {Config} instances.
      #
      # @return [Hash]
      #
      # @api public
      def values
        # Ensure all settings are represented in values
        _settings.each { |setting| self[setting.name] unless _values.key?(setting.name) }

        _values
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
      def configure
        raise ArgumentError, "you need to pass a block" unless block_given?

        to_configure = self.to_configure

        yield(to_configure)

        return self if to_configure.updated_values.none?

        @_values = @_values.dup

        to_configure.updated_values.each do |key, val|
          new_val = val.is_a?(Config::ToConfigure) ? val.to_config : val

          next if @_values[key].eql?(new_val)

          @_values[key] = new_val
        end

        self
      end

      # @api private
      def to_configure
        Config::ToConfigure.new(self)
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

      def initialize_copy(source)
        super
        @_values = source._values.dup
      end
    end
  end
end
