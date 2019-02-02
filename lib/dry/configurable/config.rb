require 'concurrent/hash'

module Dry
  module Configurable
    # @private
    class Config
      class << self
        def [](settings)
          ::Class.new(Config) do
            @settings = settings
            singleton_class.attr_reader :settings

            @lock = ::Mutex.new
            @config_defined = false
          end
        end

        def define_accessors!
          @lock.synchronize do
            break if config_defined?

            settings.each do |setting|
              define_method(setting.name) do
                @config[setting.name]
              end

              define_method("#{setting.name}=") do |value|
                raise FrozenConfig, 'Cannot modify frozen config' if frozen?
                @config[setting.name] = setting.processor.(value)
              end
            end

            @config_defined = true
          end
        end

        def config_defined?
          @config_defined
        end
      end

      attr_reader :config
      protected :config

      def initialize
        @config = ::Concurrent::Hash.new
        @lock = ::Mutex.new
        @defined = false
      end

      def settings
        self.class.settings
      end

      def defined?
        @defined
      end

      def define!(parent_config = EMPTY_HASH)
        @lock.synchronize do
          break if self.defined?

          self.class.define_accessors!
          set_values!(parent_config)

          @defined = true
        end

        self
      end

      def finalize!
        define!
        config.freeze
        freeze
      end

      def to_h
        config.each_with_object({}) do |(key, value), hash|
          case value
          when Config
            hash[key] = value.to_h
          else
            hash[key] = value
          end
        end
      end
      alias to_hash to_h

      def [](name)
        raise_unknown_setting_error(name) unless key?(name.to_sym)
        public_send(name)
      end

      def []=(name, value)
        raise_unknown_setting_error(name) unless key?(name.to_sym)
        public_send("#{name}=", value)
      end

      def key?(name)
        settings.name?(name)
      end

      private

      def set_values!(parent_config)
        settings.each do |setting|
          if parent_config.key?(setting.name)
            config[setting.name] = parent_config[setting.name]
          elsif setting.undefined?
            config[setting.name] = nil
          elsif setting.node?
            value = setting.value.create_config
            value.define!
            self[setting.name] = value
          else
            self[setting.name] = setting.value
          end
        end
      end

      def raise_unknown_setting_error(name)
        raise ArgumentError, "+#{name}+ is not a setting name"
      end
    end
  end
end
