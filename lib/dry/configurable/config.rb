# frozen_string_literal: true

require 'dry/configurable/constants'
require 'dry/configurable/error'

module Dry
  module Configurable
    # Config exposes setting values through a convenient API
    #
    # @api public
    class Config
      # @api private
      attr_reader :settings

      # @api private
      def initialize(settings)
        @settings = settings
        @values = nil
      end

      # Get config value by a key
      #
      # @param [String,Symbol] name
      #
      # @return Config value
      def [](name)
        values.fetch(name)
      rescue KeyError
        raise ArgumentError, "+#{name}+ is not a setting name"
      end

      # Set config value.
      # Note that finalized configs cannot be changed.
      #
      # @param [String,Symbol] name
      # @param [Object] value
      def []=(name, value)
        public_send(:"#{name}=", value)
      end

      # Dump config into a hash
      #
      # @return [Hash]
      #
      # @api public
      def to_h
        values.map { |key, value| [key, value.respond_to?(:to_h) ? value.to_h : value] }.to_h
      end
      alias_method :to_hash, :to_h

      # @api public
      def clone
        clone = dup
        clone.freeze if frozen?
        clone
      end

      # @api public
      def dup
        self.class.new(settings.dup)
      end

      # @api private
      def values
        @values || settings.map(&:to_h).reduce(:merge) || EMPTY_HASH
      end

      # @api private
      def finalize!
        @values = values.freeze
        freeze
      end

      # @api private
      def pristine
        self.class.new(settings.pristine)
      end

      # @api private
      def respond_to_missing?(meth, include_private = false)
        super || settings.key?(resolve(meth))
      end

      private

      # @api private
      def method_missing(meth, *args)
        setting = settings[meth.to_s.tr('=', '').to_sym]

        super unless setting

        if meth.to_s.end_with?('=')
          raise FrozenConfig, 'Cannot modify frozen config' if frozen?

          settings[setting.name] = setting.with(value: args[0])

          self
        else
          setting.value
        end
      end
    end
  end
end
