# frozen_string_literal: true

module Dry
  # Shared errors
  #
  # @api public
  module Configurable
    Error = Class.new(::StandardError)

    FrozenConfigError = Class.new(Error)
  end
end
