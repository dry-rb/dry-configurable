# frozen_string_literal: true

require_relative "support/coverage"
require "pathname"

SPEC_ROOT = Pathname(__FILE__).dirname

begin
  require "pry-byebug"
rescue LoadError
end

Dir[Pathname(__FILE__).dirname.join("support/**/*.rb").to_s].sort.each do |file|
  require file
end

require "dry/configurable"
require "dry/configurable/test_interface"
require "dry/core/deprecations"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
end
