module Dry
  module Configurable
    # @private
    class Config
      DEFAULT_PROCESSOR = ->(v) { v }.freeze

      def self.create(settings)
        klass = Class.new(self)
        klass.__send__(:attr_reader, *settings.map(&:name))
        settings.each do |setting|
          klass.__send__(:define_method, "#{setting.name}=") do |value|
            instance_variable_set(
              "@#{setting.name}",
              setting.processor.call(value)
            )
          end
        end
        klass.new(settings)
      end

      def initialize(settings)
        settings.each do |setting|
          public_send("#{setting.name}=", setting.value) unless setting.none?
        end
      end
    end
  end
end
