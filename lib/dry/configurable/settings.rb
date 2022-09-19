# frozen_string_literal: true

module Dry
  module Configurable
    # A settings map
    #
    # @api private
    class Settings
      include Dry::Equalizer(:settings)

      include Enumerable

      # @api private
      attr_reader :settings

      # @api private
      def initialize(settings = EMPTY_ARRAY)
        @settings = settings.each_with_object({}) { |s, m| m[s.name] = s }
      end

      # @api private
      def <<(setting)
        settings[setting.name] = setting
        self
      end

      # @api private
      def [](name)
        settings[name]
      end

      # @api private
      def key?(name)
        keys.include?(name)
      end

      # @api private
      def keys
        settings.keys
      end

      # @api private
      def each(&block)
        settings.each_value(&block)
      end

      private

      def initialize_copy(source)
        @settings = source.settings.dup
      end
    end
  end
end
