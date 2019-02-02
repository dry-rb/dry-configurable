require 'concurrent/hash'

module Dry
  module Configurable
    # @private
    class Config
      def self.[](settings)
        ::Class.new(Config) do
          @settings = settings
          singleton_class.attr_reader :settings

          @defintion_mutex = ::Mutex.new
          @accessors_defined = false
        end
      end

      def self.define_accessors!
        @defintion_mutex.synchronize do
          break if @accessors_defined

          settings.each do |setting|
            define_method(setting.name) do
              @config[setting.name]
            end

            define_method("#{setting.name}=") do |value|
              raise FrozenConfig, 'Cannot modify frozen config' if frozen?
              @config[setting.name] = setting.processor.(value)
            end
          end

          @accessors_defined = true
        end
      end

      attr_reader :config
      protected :config

      def initialize(lock: ::Mutex.new)
        @config = ::Concurrent::Hash.new
        @lock = lock
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

          settings.each do |setting|
            if parent_config.key?(setting.name)
              config[setting.name] = parent_config[setting.name]
            elsif setting.undefined?
              config[setting.name] = nil
            elsif setting.node?
              value = setting.value.create_config
              value.define!
              public_send("#{setting.name}=", value)
            else
              public_send("#{setting.name}=", setting.value)
            end
          end

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
        raise_unknown_setting_error(name) unless setting?(name)
        public_send(name)
      end

      def []=(name, value)
        raise_unknown_setting_error(name) unless setting?(name)
        public_send("#{name}=", value)
      end

      def key?(name)
        config.key?(name)
      end

      private

      def raise_unknown_setting_error(name)
        raise ArgumentError, "+#{name}+ is not a setting name"
      end

      def setting?(name)
        config.key?(name.to_sym)
      end
    end
  end
end
