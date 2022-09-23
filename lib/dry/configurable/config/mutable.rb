# frozen_string_literal: true

require "dry/core/constants"

module Dry
  module Configurable
    class Config
      module Mutable
        # Sets a config value.
        #
        # Note that finalized configs cannot be changed.
        #
        # @param [String,Symbol] name
        # @param [Object] value
        #
        # @api public
        def []=(name, value)
          raise FrozenError, "Cannot modify frozen config" if frozen?

          name = name.to_sym

          unless (setting = _settings[name])
            raise ArgumentError, "+#{name}+ is not a setting name"
          end

          _values[name] = setting.constructor.(value)
        end

        # Updates config with new values.
        #
        # @param values [Hash, #to_hash] A hash with new values
        #
        # @return [Config]
        #
        # @api public
        def update(values)
          values.each do |key, value|
            if self[key].is_a?(self.class)
              unless value.respond_to?(:to_hash)
                raise ArgumentError, "#{value.inspect} is not a valid setting value"
              end

              self[key].update(value.to_hash)
            else
              self[key] = value
            end
          end
          self
        end
      end
    end
  end
end
