# frozen_string_literal: true

require "set"

require "dry/core/equalizer"

module Dry
  module Configurable
    # This class represents a setting and is used internally.
    #
    # @api private
    class Setting
      include Dry::Equalizer(:name, :children, :options, inspect: false)

      OPTIONS = %i[default reader constructor cloneable settings config_class].freeze

      DEFAULT_CONSTRUCTOR = -> v { v }.freeze

      CLONEABLE_VALUE_TYPES = [Array, Hash, Set, Config].freeze

      # @api private
      attr_reader :name

      # @api private
      attr_reader :default

      # @api private
      attr_reader :options

      # @api private
      attr_reader :children

      # @api private
      def self.cloneable_value?(value)
        CLONEABLE_VALUE_TYPES.any? { |type| value.is_a?(type) }
      end

      # @api private
      def initialize(name, default: Undefined, children: EMPTY_ARRAY, **options)
        @name = name
        @default = default
        @children = children
        @options = options
      end

      # @api private
      def constructor
        options[:constructor] || DEFAULT_CONSTRUCTOR
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
          value = constructor.(Dry::Core::Constants::Undefined.coalesce(default, nil))
          cloneable? ? value.dup : value
        end
      end
    end
  end
end
