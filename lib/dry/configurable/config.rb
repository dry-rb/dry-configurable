require 'dry-types'
require 'dry/core/deprecations'

module Dry
  module Configurable
    # @api private
    class Config < Dry::Struct
      ANY = Dry::Types['any']

      extend Helpers

      class << self
        private :attribute

        def setting(name, type_or_value = nil, &block)
          if block
            attribute(name, Class.new(superclass), &block)
          else
            type = if type?(type_or_value)
                     type_or_value
                   else
                     Dry::Core::Deprecations.warn(deprecation_warning, tag: :'dry-configurable')
                     ANY.default(type_or_value)
                   end
            attribute(name, type)
          end
        end

        def deprecation_warning
          'Use of non Dry::Types::Type as default value will be deprecated in the future. '\
          'Just replace your default value with a Dry::Types type ex: `Dry::Types[\'string\'].default(\'foo\')`'
        end

        private :deprecation_warning
      end
    end
  end
end
