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
            @config[setting.name] = setting.processor.call(value)
          end
        end

        klass.new(settings)
      end

      def initialize(settings)
        @config = ::Concurrent::Hash.new

        settings.each do |setting|
          if setting.none?
            @config[setting.name] = nil
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
        @config.each_value do |value|
          next unless nested_config?(value)
          value.finalize!
        end
        freeze
      end

      def to_h
        @config.each_with_object({}) do |tuple, hash|
          key, value = tuple

          hash[key] = nested_config?(value) ? value.to_h : value
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

      def nested_config?(value)
        value.is_a?(::Dry::Configurable::Config) ||
          value.is_a?(::Dry::Configurable::NestedConfig)
      end

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
