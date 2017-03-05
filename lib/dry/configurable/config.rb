module Dry
  module Configurable
    # @private
    class Config
      DEFAULT_PROCESSOR = ->(v) { v }.freeze

      def self.create(settings)
        klass = ::Class.new(self)

        settings.each do |setting|
          klass.__send__(:define_method, setting.name) do
            @config[setting.name]
          end

          klass.__send__(:define_method, "#{setting.name}=") do |value|
            raise_frozen_config if frozen?
            v = setting.preprocessor ? setting.preprocessor.(value) : value
            @config[setting.name] = setting.processor.call(v)
          end
        end

        klass.new(settings)
      end

      def initialize(settings)
        @config = ::Concurrent::Hash.new

        settings.each do |setting|
          if setting.none?
            v = setting.preprocessor ? setting.preprocessor.() : nil
            @config[setting.name] = v
          else
            public_send("#{setting.name}=", setting.value)
          end
        end
      end

      def dup
        dup = super
        dup.instance_variable_set(:@config, @config.dup)
        dup
      end

      def clone
        clone = super
        clone.instance_variable_set(:@config, @config.clone)
        clone
      end

      def finalize!
        @config.freeze
        freeze
      end

      def to_h
        @config.each_with_object({}) do |tuple, hash|
          key, value = tuple

          case value
          when ::Dry::Configurable::Config, ::Dry::Configurable::NestedConfig
            hash[key] = value.to_h
          else
            hash[key] = value
          end
        end
      end
      alias to_hash to_h

      def [](name)
        raise_unknown_setting_error(name) unless setting?(name)
        public_send(name)
      end

      def []=(name, value)
        raise_unknown_setting_error(name) unless setting?(name)
        public_send("#{name}=", value)
      end

      private

      def raise_frozen_config
        raise FrozenConfig, 'Cannot modify frozen config'
      end

      def raise_unknown_setting_error(name)
        raise ArgumentError, "+#{name}+ is not a setting name"
      end

      def setting?(name)
        @config.key?(name.to_sym)
      end
    end
  end
end
