require 'concurrent/hash'

module Dry
  module Configurable
    # @private
    class Config
      class << self
        # @private
        def [](settings)
          ::Class.new(Config) do
            @settings = settings
            singleton_class.send(:attr_reader, :settings)

            @lock = ::Mutex.new
            @config_defined = false
          end
        end

        # @private
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

        # @private
        def config_defined?
          @config_defined
        end
      end

      def initialize
        @config = ::Concurrent::Hash.new
        @lock = ::Mutex.new
        @defined = false
      end

      def defined?
        @defined
      end

      # @private
      def define!(parent_config = EMPTY_HASH)
        @lock.synchronize do
          break if self.defined?

          self.class.define_accessors!
          set_values!(parent_config)

          @defined = true
        end

        self
      end

      # @private
      def finalize!
        define!
        @config.freeze
        freeze
      end

      # Serialize config to a Hash
      #
      # @return [Hash]
      #
      # @api public
      def to_h
        @config.each_with_object({}) do |(key, value), hash|
          case value
          when Config
            hash[key] = value.to_h
          else
            hash[key] = value
          end
        end
      end
      alias to_hash to_h

      # Get config value by a key
      #
      # @param [String,Symbol] name
      #
      # @return Config value
      def [](name)
        raise_unknown_setting_error(name) unless key?(name.to_sym)
        public_send(name)
      end

      # Set config value.
      # Note that finalized configs cannot be changed.
      #
      # @param [String,Symbol] name
      # @param [Object] value
      def []=(name, value)
        raise_unknown_setting_error(name) unless key?(name.to_sym)
        public_send("#{name}=", value)
      end

      # Whether config has a key
      #
      # @param [Symbol] key
      # @return [Bool]
      def key?(name)
        self.class.settings.name?(name)
      end

      # Recursively update values from a hash
      #
      # @param [Hash] values to set
      # @return [Config]
      def update(values)
        values.each do |key, value|
          if self[key].is_a?(Config)
            self[key].update(value)
          else
            self[key] = value
          end
        end
        self
      end

      private

      # @private
      def set_values!(parent)
        self.class.settings.each do |setting|
          if parent.key?(setting.name) && !setting.node?
            @config[setting.name] = parent[setting.name]
          elsif setting.undefined?
            @config[setting.name] = nil
          elsif setting.node?
            value = setting.value.create_config
            value.define!(parent.fetch(setting.name, EMPTY_HASH))
            self[setting.name] = value
          else
            self[setting.name] = setting.value
          end
        end
      end

      # @private
      def raise_unknown_setting_error(name)
        raise ArgumentError, "+#{name}+ is not a setting name"
      end
    end
  end
end
