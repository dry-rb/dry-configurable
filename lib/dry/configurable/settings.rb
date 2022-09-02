# frozen_string_literal: true

require "concurrent/map"

module Dry
  module Configurable
    # A settings map
    #
    # @api private
    class Settings
      include Dry::Equalizer(:elements)

      include Enumerable

      # @api private
      attr_reader :elements

      # @api private
      attr_reader :target

      # @api private
      def initialize(elements = EMPTY_ARRAY, target: nil) # FIXME: this shouldn't be optional, but I wanted unit tests to pass for now
        initialize_elements(elements)
        @target = target
      end

      def copy_for_target(new_target)
        self.class.new(elements.values, target: new_target)
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

      # WIP - prob not needed if this is containing definitions only
      # def pristine
      #   self.class.new(map(&:pristine))
      # end

      # WIP - prob not needed if this is containing definitions only
      # def finalize!(freeze_values: false)
      #   each { |element| element.finalize!(freeze_values: freeze_values) }
      #   freeze
      # end
      def finalize!(freeze_values: false)
        # TODO: work out what to do
        freeze
      end

      private

      # @api private
      def initialize_copy(source)
        initialize_elements(source.map(&:dup))
      end

      # @api private
      def initialize_elements(elements)
        @elements = elements.each_with_object(Concurrent::Map.new) { |s, m|
          m[s.name] = s
        }
      end
    end
  end
end
