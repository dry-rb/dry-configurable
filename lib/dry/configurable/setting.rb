# frozen_string_literal: true

require "set"

module Dry
  module Configurable
    # This class represents a setting and is used internally.
    #
    # @api private
    class Setting
      include Dry::Equalizer(:name, :default, :constructor, :children, :options, inspect: false)

      OPTIONS = %i[default reader constructor cloneable settings config_class].freeze

      DEFAULT_CONSTRUCTOR = -> v { v }.freeze

      CLONEABLE_VALUE_TYPES = [Array, Hash, Set, Config].freeze

      # @api private
      attr_reader :name

      # @api private
      attr_reader :default

      # @api private
      attr_reader :constructor

      # @api private
      attr_reader :children

      # @api private
      attr_reader :options

      # @api private
      def self.cloneable_value?(value)
        CLONEABLE_VALUE_TYPES.any? { |type| value.is_a?(type) }
      end

      # @api private
      def initialize(
        name,
        default:,
        constructor: DEFAULT_CONSTRUCTOR,
        children: EMPTY_ARRAY,
        **options
      )
        @name = name
        @default = default
        @constructor = constructor
        @children = children
        @options = options
      end

      # @api private
      def reader?
        options[:reader].equal?(true)
      end

      # @api private
      def cloneable?
        children.any? || options.fetch(:cloneable) { Setting.cloneable_value?(default) }
      end

      # @api private
      def to_value
        if children.any?
          (options[:config_class] || Config).new(children)
        else
          value = default
          value = constructor.(value) unless value.eql?(Undefined)

          cloneable? ? value.dup : value
        end
      end
    end
  end
end
