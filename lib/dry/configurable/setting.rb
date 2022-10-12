# frozen_string_literal: true

require "set"

module Dry
  module Configurable
    # A defined setting.
    #
    # @api public
    class Setting
      include Dry::Equalizer(:name, :default, :constructor, :children, :options, inspect: false)

      OPTIONS = %i[default reader constructor cloneable settings config_class].freeze

      DEFAULT_CONSTRUCTOR = -> v { v }.freeze

      CLONEABLE_VALUE_TYPES = [Array, Hash, Set, Config].freeze

      # @api public
      attr_reader :name

      # @api public
      attr_reader :default

      # @api public
      attr_reader :cloneable

      # @api public
      attr_reader :constructor

      # @api public
      attr_reader :children

      # @api public
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
        @cloneable = children.any? || options.fetch(:cloneable) {
          Setting.cloneable_value?(default)
        }
        @constructor = constructor
        @children = children
        @options = options
      end

      # @api private
      def reader?
        options[:reader].equal?(true)
      end

      # @api public
      def cloneable?
        cloneable
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
