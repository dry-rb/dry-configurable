# frozen_string_literal: true

require 'dry/configurable/constants'
require 'dry/configurable/errors'

module Dry
  module Configurable
    # Config exposes setting values through a convenient API
    #
    # @api public
    class Config
      # @api private
      attr_reader :settings

      # @api private
      attr_reader :resolved

      # @api private
      def initialize(settings)
        @settings = settings
        @resolved = Concurrent::Map.new
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
        values.map { |key, value| [key, value.is_a?(self.class) ? value.to_h : value] }.to_h
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
        setting = settings[resolve(meth)]

        super unless setting

        if setting.writer?(meth)
          raise FrozenConfig, 'Cannot modify frozen config' if frozen?

          settings << setting.with(value: args[0])

          self
        else
          setting.value
        end
      end

      # @api private
      def resolve(meth)
        resolved.fetch(meth) { resolved[meth] = meth.to_s.tr('=', '').to_sym }
      end
    end
  end
end
