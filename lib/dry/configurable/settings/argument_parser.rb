# frozen_string_literal: true

module Dry
  # Argument parser
  #
  # Passing and array or arguments, it will decide which one are arguments
  # and which one are options.
  #
  # We have a limitation if setting the value without options, as a hash
  # having the same key as one of the valid options, will parse the value
  # as options. In this case, all unknown options will be reject with an exception.
  #
  # @example
  #   p = Dry::Configurable::ArgumentParser.new.('db:sqlite', reader: true)
  #
  #   p[0] # => 'db:sqlite'
  #   p[1] # => ArgumentParser::DEFAULT_PROCESSOR
  #   p[2] # => { reader: true }
  module Configurable
    class Settings
      # @private
      class ArgumentParser
        DEFAULT_PROCESSOR = ->(v) { v }

        # @private
        def call(val, opts, block)
          if block && block.parameters.empty?
            raise ArgumentError unless Undefined.equal?(opts)

            processor = DEFAULT_PROCESSOR

            value, options = Settings.capture(&block), val
          else
            processor = block || DEFAULT_PROCESSOR

            if Undefined.equal?(opts) && val.is_a?(Hash) && val.key?(:reader)
              value, options = Undefined, val
            else
              value, options = val, opts
            end
          end

          [value, processor, options(**Undefined.default(options, EMPTY_HASH))]
        end

        def options(reader: false)
          { reader: reader }
        end
      end
    end
  end
end
