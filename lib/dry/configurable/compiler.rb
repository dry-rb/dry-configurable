# frozen_string_literal: true

module Dry
  module Configurable
    # Setting compiler used internally by the DSL
    #
    # @api private
    class Compiler
      # FIXME: This isn't called from anywhere???? (Oh, it's called from inside visit_nested)
      def call(ast, settings_class = Class.new(Settings))
        # Settings.new.tap do |settings|
        #   ast.each do |node|
        #     settings << visit(node)
        #   end
        # end

        ast.each do |node|
          visit(node, settings_class)
        end

        settings_class
      end

      # @api private
      def visit(node, settings_class = Class.new(Settings))
        type, rest = node
        public_send(:"visit_#{type}", rest, settings_class)
      end

      # @api private
      def visit_setting(node, settings_class)
        name, opts = node
        # Setting.new(name, **opts)
        settings_class.define_setting(name, **opts)
      end

      # @api private
      def visit_nested(node, settings_class)
        # [:setting, [name.to_sym, options]], DSL.new(&block).ast]
        parent, children = node

        # visit(settings_class, parent).nested(call(children))

        nested_class = call(children)

        # parent = [:setting, [name.to_sym, options]]
        parent_type, parent_rest = parent
        parent_rest.last[:default] = nested_class.new

        visit([parent_type, parent_rest], settings_class)
      end
    end
  end
end
