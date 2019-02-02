module Dry
  # Argument parser
  #
  # Passing and array or arguments, it will decide wich one are arguments
  # and which one are options.
  #
  # We have a limitation if setting the value without options, as a hash
  # having the same key as one of the valid options, will parse the value
  # as options.
  #
  # @example
  #   p = Dry::Configurable::ArgumentParser.new(['db:sqlite', { reader: true }])
  #
  #   p.value # => 'db:sqlite'
  #   p.options # => { reader: true }
  #
  #   Dry::Configurable::ArgumentParser.call(['db:sqlite', { reader: true }])
  #    # => [ 'db:sqlite', { reader: true } ]
  module Configurable
    class Settings
      # @private
      class ArgumentParser
        DEFAULT_PROCESSOR = -> (v) { v }

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

          [value, processor, options(Undefined.default(options, EMPTY_HASH))]
        end

        def options(reader: false)
          { reader: reader }
        end
      end
    end
  end
end
