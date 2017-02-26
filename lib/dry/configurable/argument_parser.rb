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
  #   p = Dry::Configurable::ArgumentParser.new(['db:sqlite', { reader: true })
  #
  #   p.value # => 'db:sqlite'
  #   p.options # => { reader: true }
  #
  #   Dry::Configurable::ArgumentParser.call(['db:sqlite', { reader: true })
  #    # => [ 'db:sqlite', { reader: true } ]

  module Configurable
    # @private
    class ArgumentParser
      VALID_OPTIONS = %i(reader)

      def self.call(data)
        parsed = new(data)
        [ parsed.value, parsed.options ]
      end

      def initialize(data)
        @data = data
      end

      def value
        parse_args[:value]
      end

      def options
        parse_args[:options]
      end

      private

      attr_reader :data

      # @private
      def default_args
        { value: nil, options: {} }
      end

      # @private
      def parse_args
        return default_args if data.empty?
        if data.size > 1
          { value: data.first, options: check_options(data.last) }
        else
          default_args.merge(check_for_value_or_options(data.first))
        end
      end

      # @private
      def check_options(opts)
        return {} if opts.empty?
        opts.select { |k, _| VALID_OPTIONS.include?(k) }
      end

      # @private
      def check_for_value_or_options(args)
        case args
        when Hash
          parse_hash(args)
        else
          { value: args }
        end
      end

      # @private
      def parse_hash(args)
        if hash_include_options_key(args)
          { options: check_options(args) }
        else
          { value: args }
        end
      end

      # @private
      def hash_include_options_key(hash)
        hash.any?{ |k, _| VALID_OPTIONS.include?(k) }
      end
    end
  end
end
