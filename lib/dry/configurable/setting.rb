module Dry
  module Configurable
    # This class represents a setting and is used internally.
    #
    # @private
    class Setting
      attr_reader :name

      attr_reader :options

      attr_reader :processor

      def initialize(name, value, processor, options = EMPTY_HASH)
        @name = name.to_sym
        @value = value
        @processor = processor
        @options = options
      end

      def value
        Undefined.default(@value, nil)
      end

      def undefined?
        Undefined.equal?(@value)
      end

      def reader?
        options[:reader]
      end

      def node?
        Settings === @value
      end
    end
  end
end
