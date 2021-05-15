# frozen_string_literal: true

require 'dry/configurable/constants'
require 'dry/configurable/setting'
require 'dry/configurable/settings'
require 'dry/configurable/compiler'
require 'dry/configurable/dsl/args'
require 'dry/core/deprecations'

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
      def setting(name, *args, &block)
        unless VALID_NAME.match?(name.to_s)
          raise ArgumentError, "#{name} is not a valid setting name"
        end

        args = Args.new(args)

        args.ensure_valid_options

        default, opts = args

        if block && !block.arity.zero?
          Dry::Core::Deprecations.announce(
            'passing a constructor as a block',
            'Provide a `constructor:` keyword argument instead',
            tag: 'dry-configurable'
          )
          opts = opts.merge(constructor: block)
          block = nil
        end

        node = [:setting, [name.to_sym, default, opts == default ? EMPTY_HASH : opts]]

        if block
          ast << [:nested, [node, DSL.new(&block).ast]]
        else
          ast << node
        end

        compiler.visit(ast.last)
      end
    end
  end
end
