module Dry
  module Configurable

    # @private
    class NullConfig < Dry::Struct
      transform_types do |type|
        if type.is_a?(Class) && type <= Dry::Struct || type.default?
          type
        elsif type.optional?
          type.default(nil)
        else
          type.optional.default(nil)
        end
      end

      class << self
        private :attribute

        def setting(name, type = nil, &block)
          if block
            attribute(name, Class.new(NullConfig), &block)
          else
            attribute(name, type)
          end

          define_method("#{name}=") do |value|
            @attributes = @attributes.merge(name => value)
          end
        end
      end
    end
  end
end
