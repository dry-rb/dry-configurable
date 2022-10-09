# frozen_string_literal: true

module Dry
  module Configurable
    # A settings map
    #
    # @api private
    class Settings
      include Dry::Equalizer(:parent_settings, :settings)

      include Enumerable

      # @return [Array<Hash>]
      #
      # @api private
      attr_reader :parent_settings

      # @api private
      attr_reader :settings

      # @api private
      def initialize(settings = EMPTY_ARRAY)
        @parent_settings = []
        @settings = settings.each_with_object({}) { |s, m| m[s.name] = s }
      end

      # @api private
      private def initialize_copy(source)
        @parent_settings = source.parent_settings.dup
        @settings = source.settings.dup
      end

      # @api private
      def dup_for_child
        dup.tap do |child_settings|
          child_settings.parent_settings << settings
        end
      end

      # @api private
      def <<(setting)
        settings[setting.name] = setting
        self
      end

      # @api private
      def [](name)
        all_settings[name]
      end

      # @api private
      def key?(name)
        keys.include?(name)
      end

      # @api private
      def keys
        all_settings.keys
      end

      # @api private
      def each(&block)
        all_settings.each_value(&block)
      end

      private

      def all_settings
        {**parent_settings.reduce({}, :merge), **settings}
      end
    end
  end
end
