# frozen_string_literal: true

module Dry
  module Configurable
    class Extension < Module
      # @api private
      attr_reader :config_class

      # @api private
      def initialize(config_class: Configurable::Config)
        super()
        @config_class = config_class
        freeze
      end

      # @api private
      def extended(klass)
        super
        klass.extend(ClassMethods)
        klass.instance_variable_set(:@__config_extension__, self)
      end

      # @api private
      def included(klass)
        raise AlreadyIncluded if klass.include?(InstanceMethods)

        super

        klass.class_eval do
          extend(ClassMethods)
          include(InstanceMethods)
          prepend(Initializer)

          class << self
            undef :config
            undef :configure
          end
        end

        klass.instance_variable_set(:@__config_extension__, self)
      end
    end
  end
end
