module Dry
  module Configurable
    class Config < Dry::Struct
      class << self
        private :attribute

        def setting(name, type = nil, &block)
          if block
            attribute(name, Class.new(self.superclass), &block)
          else
            attribute(name, type)
          end
        end
      end
    end
  end
end
