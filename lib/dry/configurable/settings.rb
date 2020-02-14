# frozen_string_literal: true

require 'concurrent/map'

module Dry
  module Configurable
    # A settings map
    #
    # @api private
    class Settings
      include Enumerable

      # @api private
      attr_reader :elements

      # @api private
      def initialize(settings = [])
        @elements = settings.each_with_object(Concurrent::Map.new) { |s, m| m[s.name] = s }
      end

      # @api private
      def <<(setting)
        elements[setting.name] = setting
        self
      end

      # @api private
      def [](name)
        elements[name]
      end

      # @api private
      def []=(name, element)
        elements[name] = element
      end

      # @api private
      def key?(name)
        keys.include?(name)
      end

      # @api private
      def keys
        elements.keys
      end

      # @api private
      def each(&block)
        elements.values.each(&block)
      end

      # @api private
      def pristine
        self.class.new(map(&:pristine))
      end

      # @api private
      def clone
        clone = dup
        clone.freeze if frozen?
        clone
      end

      # @api private
      def dup
        self.class.new(map(&:clone))
      end
    end
  end
end
