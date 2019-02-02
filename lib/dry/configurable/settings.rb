require 'concurrent/array'
require 'dry/configurable/settings/argument_parser'
require 'dry/configurable/setting'
require 'dry/configurable/config'

module Dry
  module Configurable
    class Settings
      Parser = ArgumentParser.new.freeze

      class DSL
        def self.call(&block)
          new.instance_exec do
            instance_exec(&block)
            @settings
          end
        end

        def initialize
          @settings = Settings.new
        end

        def setting(*args, &block)
          @settings.add(*args, &block)
        end
      end

      def self.capture(&block)
        DSL.(&block)
      end

      attr_reader :settings

      attr_reader :config_class

      def initialize(settings = ::Concurrent::Array.new)
        @settings = settings
        @config_class = Config[self]
        yield(self) if block_given?
      end

      def add(key, value = Undefined, options = Undefined, &block)
        extended = singleton_class < Configurable
        raise_already_defined_config(key) if extended && configured?

        Setting.new(key, *Parser.(value, options, block)).tap do |s|
          settings << s
        end
      end

      def each
        settings.each { |s| yield(s) }
      end

      def map
        settings.map { |s| yield(s) }
      end

      def empty?
        settings.empty?
      end

      def dup
        Settings.new(settings.dup)
      end

      def freeze
        settings.freeze
        super
      end

      def create_config
        config_class.new
      end

      def config_defined?
        config_class.config_defined?
      end
    end
  end
end
