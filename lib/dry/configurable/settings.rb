require 'set'
require 'concurrent/array'
require 'dry/configurable/settings/argument_parser'
require 'dry/configurable/setting'
require 'dry/configurable/config'

module Dry
  module Configurable
    # A collection of settings. This is not part of the public API.
    #
    # @private
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

      # Capture nested config definition
      #
      # @return [Dry::Configurable::Setting]
      def self.capture(&block)
        DSL.(&block)
      end

      attr_reader :settings

      attr_reader :config_class

      attr_reader :index
      private :index

      def initialize(settings = ::Concurrent::Array.new)
        @settings = settings
        @config_class = Config[self]
        @index = settings.map { |s| [s.name, s] }.to_h
        yield(self) if block_given?
      end

      def add(key, value = Undefined, options = Undefined, &block)
        extended = singleton_class < Configurable
        raise_already_defined_config(key) if extended && configured?

        *args, opts = Parser.(value, options, block)

        Setting.new(key, *args, { **opts, reserved: reserved?(key) }).tap do |s|
          settings << s
          index[s.name] = s
          @names = nil
        end
      end

      def each
        settings.each { |s| yield(s) }
      end

      def names
        @names ||= index.keys.to_set
      end

      def [](name)
        index[name]
      end

      def empty?
        settings.empty?
      end

      def name?(name)
        index.key?(name)
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

      def reserved?(name)
        reserved_names.include?(name)
      end

      def reserved_names
        @reserved_names ||= [
          config_class.instance_methods(false),
          config_class.superclass.instance_methods(false),
          %i(class public_send)
        ].reduce(:+)
      end
    end
  end
end
