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
      attr_reader :lookup_cache

      # @api private
      def initialize(settings = EMPTY_ARRAY)
        @parent_settings = []
        @settings = settings.each_with_object({}) { |s, m| m[s.name] = s }
        @lookup_cache = {}
      end

      # @api private
      private def initialize_copy(source)
        @parent_settings = source.parent_settings.dup
        @settings = source.settings.dup
        @lookup_cache = source.lookup_cache.dup
      end

      # @api private
      def dup_for_child
        dup.tap { |child| child.add_parent(settings) }
      end

      # @api private
      def add_parent(parent)
        # Use length for all_settings cache invalidation
        parent_settings << [parent, parent.length]
      end

      # @api private
      def <<(setting)
        @all_settings = nil # bit gross
        settings[setting.name] = setting
        self
      end

      # @api private
      def [](name)
        lookup_cache.fetch(name) {
          lookup_cache[name] = all_settings[name]
        }
      end

      # @api private
      def each(&block)
        all_settings.each_value(&block)
      end

      private

      def all_settings
        if parent_settings.none?
          settings
        elsif @all_settings && parent_settings.all? { |(parent, cached_length)| parent.length == cached_length }
          # Our cache is valid; no new parent settings have been defined since it was built
          @all_settings
        else
          @all_settings = {}.tap { |hsh|
            parent_settings.each_with_index do |(parent, _length), index|
              parent_settings[index][1] = parent.length
              hsh.merge!(parent)
            end

            hsh.merge!(settings)
          }
        end
      end
    end
  end
end
