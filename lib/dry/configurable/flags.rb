# frozen_string_literal: true

require "dry/core/class_attributes"

module Dry
  module Configurable
    extend Core::ClassAttributes

    # Set to false to suppress deprecation warning when a setting default is provided as a
    # positional argument
    defines :warn_on_setting_positional_default
    warn_on_setting_positional_default true

    # Set to false to suppress deprecation warning when a setting constructor is provided
    # as a block
    defines :warn_on_setting_constructor_block
    warn_on_setting_constructor_block true
  end
end
