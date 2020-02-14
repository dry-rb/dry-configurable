# frozen_string_literal: true

require 'dry/equalizer'

require 'dry/configurable/constants'
require 'dry/configurable/config'

module Dry
  module Configurable
    # This class represents a setting and is used internally.
    #
    # @api private
    class Setting
      include Dry::Equalizer(:name, :options)

      OPTIONS = %i[value default reader constructor settings].freeze

      DEFAULT_CONSTRUCTOR = -> v { v }.freeze

      # @api private
      attr_reader :name

      # @api private
      attr_reader :writer_name

      # @api private
      attr_reader :default

      # @api private
      attr_reader :options

      # @api private
      def self.[](name, **options)
        type = options.key?(:settings) ? Nested : Setting
        type.new(name, options)
      end

      # Specialized Setting which includes nested settings
      #
      # @api private
      class Nested < Setting
        # @api private
        def pristine
          with(value: default, settings: settings.pristine)
        end

        # @api private
        def settings
          options[:settings]
        end

        # @api private
        def config
          @config ||= Config.new(options[:settings])
        end
        alias_method :value, :config

        # @api private
        def dup
          with(options.merge(settings: settings.dup))
        end
      end

      # @api private
      def initialize(name, **options)
        @name = name
        @writer_name = :"#{name}="
        @default = options[:default]
        @options = options
      end

      # @api private
      def to_h
        { name => value }
      end

      # @api private
      def value
        @value ||= undefined? ? nil : constructor[options[:value]]
      end

      # @api private
      def pristine
        with(value: default)
      end

      # @api private
      def clone
        clone = dup
        clone.freeze if frozen?
        clone
      end

      # @api private
      def dup
        with(options.dup)
      end

      # @api private
      def with(new_opts)
        Setting[name, options.merge(new_opts)]
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
      def undefined?
        options[:value].equal?(Undefined)
      end
    end
  end
end
