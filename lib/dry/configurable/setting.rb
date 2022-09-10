# frozen_string_literal: true

require "set"

module Dry
  module Configurable
    # This class represents a setting and is used internally.
    #
    # @api private
    class Setting
      include Dry::Equalizer(:name, :children, :options, inspect: false)

      OPTIONS = %i[default reader constructor cloneable settings].freeze

      DEFAULT_CONSTRUCTOR = -> v { v }.freeze

      CLONEABLE_VALUE_TYPES = [Array, Hash, Set, Config].freeze

      # @api private
      attr_reader :name

      # @api private
      attr_reader :writer_name

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
      def initialize(name, default: Undefined, children: nil, **options)
        @name = name
        @writer_name = :"#{name}="
        @options = options
        @default = default
        @children = children
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
      def writer?(meth)
        writer_name.equal?(meth)
      end

      # @api private
      def cloneable?
        options.fetch(:cloneable) { Setting.cloneable_value?(default) }
      end

      # @api private
      def to_value
        if children
          Config.new(children)
        else
          value = constructor.(Dry::Core::Constants::Undefined.coalesce(default, nil))
          cloneable? ? value.dup : value
        end
      end

      private

      # @api private
      def initialize_copy(source)
        super

        @options = source.options.dup
        @children = source.children.dup

        if source.cloneable?
          @default = source.default.dup
        end
      end
    end
  end
end
