# frozen_string_literal: true

require "concurrent/map"

module Dry
  module Configurable
    # A settings map
    #
    # @api private
    class SettingsNew < Module
      # @api private
      attr_reader :elements

      def initialize(elements = EMPTY_ARRAY)
        super()
        initialize_elements(elements)
        @instance_mod = Module.new
      end

      def inspect
        "#<SettingsNew #{elements.map(&:name).inspect}>"
      end

      def extended(klass)
        super

        klass.include(@instance_mod)
      end

      def <<(setting)
        elements[setting.name] = setting


        # TODO: the accessor could do stuff with the constructor and default
        define_accessor(setting)
        # byebug

        self
      end

      def [](name)
        elements[name]
      end

      def key?(name)
        keys.include?(name)
      end

      def keys
        elements.keys
      end

      def each(&block)
        elements.values.each(&block)
      end

      def finalize!(freeze_values: false)
        # TODO: work out what to do
        freeze
      end

      private

      def define_accessor(setting)
        # TODO: make better
        return if instance_methods.include?(setting.name)

        settings_mod_klass = self.class

        @instance_mod.define_method(setting.name) do
          # FIXME? Ugh.
          if setting.children
            children_config = Class.new(ConfigNew)
            children_mod = settings_mod_klass.new.tap do |mod|
              setting.children.each do |child_setting|
                mod << child_setting
              end
            end
            children_config.extend(children_mod)

            @attributes[setting.name] = children_config.new
          else
            @attributes.fetch(setting.name) { setting.constructor[setting.default] }
          end
        end

        @instance_mod.define_method(:"#{setting.name}=") do |value|
          @attributes[setting.name] = setting.constructor[value]
        end

        # @instance_mod.module_eval(<<-RUBY, __FILE__, __LINE__ + 1)
        #   def #{name}                             # def email
        #     @attributes[#{name.inspect}]          #   @attributes[:email]
        #   end                                     # end

        #   def #{name}=(value)                     # def email=(value)
        #     @attributes[#{name.inspect}] = value  #   @attributes[:email] = value
        #   end                                     # end
        # RUBY
      end

      # @api private
      def initialize_elements(elements)
        @elements = elements.each_with_object(Concurrent::Map.new) { |s, m|
          m[s.name] = s
        }
      end
    end
  end
end
