# frozen_string_literal: true

require "set"

module Dry
  module Configurable
    # This class represents a setting and is used internally.
    #
    # @api private
    class Setting
      include Dry::Equalizer(:name, :children, :options, inspect: false)

      OPTIONS = %i[default reader constructor cloneable].freeze

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
      def nested(settings)
        # WIP: better way to handle this? in compiler maybe?
        #
        # Because when children are present, it'll mean other behaviors might need to change too,
        # and we're not doing that right now
        self.class.new(name, children: settings, **options)
      end

      # @api private
      # TODO: this probably needs to move elsewhere
      def finalize!(*)
        freeze
      end

      # @api private
      def constructor
        options[:constructor] || DEFAULT_CONSTRUCTOR
      end

      # @api private
      def writer?(meth)
        writer_name.equal?(meth)
      end

      # @api private
      # WIP needed?
      def cloneable?
        options.fetch(:cloneable) { Setting.cloneable_value?(default) }
      end

      def to_value
        value = constructor.(Dry::Core::Constants::Undefined.coalesce(default, nil))

        if options.fetch(:cloneable) { Setting.cloneable_value?(value) }
          value.dup
        else
          value
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
