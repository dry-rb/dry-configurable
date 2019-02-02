require 'dry/core/constants'
require 'dry/configurable/settings'
require 'dry/configurable/error'
require 'dry/configurable/version'

# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
module Dry
  # A simple configuration mixin
  #
  # @example
  #
  #   class App
  #     extend Dry::Configurable
  #
  #     setting :database do
  #       setting :dsn, 'sqlite:memory'
  #     end
  #   end
  #
  #   App.config.database.dsn = 'jdbc:sqlite:memory'
  #   App.config.database.dsn
  #     # => "jdbc:sqlite:memory'"
  #
  # @api public
  module Configurable
    include Dry::Core::Constants

    module ClassInterface
      # Add a setting to the configuration
      #
      # @param [Mixed] key
      #   The accessor key for the configuration value
      # @param [Mixed] default
      #   The default config value
      #
      # @yield
      #   If a block is given, it will be evaluated in the context of
      #   and new configuration class, and bound as the default value
      #
      # @return [Dry::Configurable::Config]
      #
      # @api public
      def setting(key, value = Undefined, options = Undefined, &block)
        extended = singleton_class < Configurable

        raise_already_defined_config(key) if extended && configured?

        setting = _settings.add(key, value, options, &block)

        if setting.reader?
          readers = extended ? singleton_class : self
          readers.define_method(setting.name) { config.public_send(setting.name) }
        end
      end

      # Return an array of setting names
      #
      # @return [Array]
      #
      # @api public
      def settings
        _settings.map(&:name)
      end

      # @private no, really...
      def _settings
        @settings
      end

      private

      # @private
      def raise_already_defined_config(key)
        raise AlreadyDefinedConfig,
              "Cannot add setting +#{key}+, #{self} is already configured"
      end

      # @private
      def inherited(subclass)
        parent = self
        subclass.instance_exec do
          @settings = parent._settings.dup
        end

        if singleton_class < Configurable
          parent_config = @config
          subclass.instance_exec do
            @config = _settings.create_config
            @config.define!(parent_config) if parent_config.defined?
          end
        end

        super
      end

      # @private
      def self.extended(base)
        base.class_eval do
          @settings = Settings.new
        end
      end
    end

    # @private
    def self.extended(base)
      base.extend(ClassInterface)
      base.class_eval do
        @config = _settings.create_config
      end
    end

    # @private
    def self.included(base)
      base.extend(ClassInterface)
    end

    def initialize
      @config = _settings.create_config
    end

    # Return configuration
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def config
      return @config if @config.defined?
      @config.define!
    end

    # Return configuration
    #
    # @yield [Dry::Configuration::Config]
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def configure
      raise FrozenConfig, 'Cannot modify frozen config' if frozen?
      yield(config)
    end

    # Finalize and freeze configuration
    #
    # @return [Dry::Configurable::Config]
    #
    # @api public
    def finalize!
      freeze
      config.finalize!
    end

    def configured?
      @config.defined?
    end

    private

    def _settings
      self.class._settings
    end
  end
end
