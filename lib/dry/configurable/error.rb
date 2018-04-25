# A collection of micro-libraries, each intended to encapsulate
# a common task in Ruby
module Dry
  module Configurable
    Error = Class.new(::StandardError)
    AlreadyDefinedConfigError = ::Class.new(Error)
    FrozenConfigError = ::Class.new(Error)
    NotConfiguredError = ::Class.new(Error)
  end
end
