module Dry
  module Configurable
    # Methods meant to be used in a testing scenario
    module TestInterface
      # Resets configuration to default values
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def reset_config
        @configured = false
        create_config
      end
    end

    # Mixes in test interface into the configurable module
    #
    # @api public
    def enable_test_interface
      extend Dry::Configurable::TestInterface
    end
  end
end
