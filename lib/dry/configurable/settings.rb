# frozen_string_literal: true

require "concurrent/map"

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
      attr_reader :target

      # @api private

      # FIXME: target shouldn't be optional, but I wanted unit tests to pass for now
      def initialize(settings = EMPTY_ARRAY, target: nil)
        @settings = settings.each_with_object(Concurrent::Map.new) { |s, m| m[s.name] = s }
        @target = target
      end

      def copy_for_target(new_target)
        self.class.new(settings.values, target: new_target)
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
        settings.values.each(&block)
      end

      private

      def initialize_copy(source)
        @settings = source.settings.dup
      end
    end
  end
end
