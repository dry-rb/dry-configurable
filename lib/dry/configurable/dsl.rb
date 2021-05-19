# frozen_string_literal: true

require 'dry/configurable/constants'
require 'dry/configurable/setting'
require 'dry/configurable/settings'
require 'dry/configurable/compiler'
require "dry/core/deprecations"

module Dry
  module Configurable
    # Setting DSL used by the class API
    #
    # @api private
    class DSL
      VALID_NAME = /\A[a-z_]\w*\z/i.freeze

      # @api private
      attr_reader :compiler

      # @api private
      attr_reader :ast

      # @api private
      def initialize(&block)
        @compiler = Compiler.new
        @ast = []
        instance_exec(&block) if block
      end

      # Register a new setting node and compile it into a setting object
      #
      # @see ClassMethods.setting
      # @api public
      # @return Setting
      def setting(name, default = Undefined, **options, &block)
        unless VALID_NAME.match?(name.to_s)
          raise ArgumentError, "#{name} is not a valid setting name"
        end

        if default != Undefined
          Dry::Core::Deprecations.announce(
            "default value as positional argument to settings",
            "Provide a `default:` keyword argument instead",
            tag: "dry-configurable"
          )
          options = options.merge(default: default)
        end

        if block && !block.arity.zero?
          Dry::Core::Deprecations.announce(
            "passing a constructor as a block",
            "Provide a `constructor:` keyword argument instead",
            tag: "dry-configurable"
          )
          options = options.merge(constructor: block)
          block = nil
        end

        ensure_valid_options(options)

        node = [:setting, [name.to_sym, options]]

        if block
          ast << [:nested, [node, DSL.new(&block).ast]]
        else
          ast << node
        end

        compiler.visit(ast.last)
      end

      private

      def ensure_valid_options(options)
        return if options.none?

        invalid_keys = options.keys - Setting::OPTIONS
        raise ArgumentError, "Invalid options: #{invalid_keys.inspect}" unless invalid_keys.empty?
      end
    end
  end
end
