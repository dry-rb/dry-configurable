# frozen_string_literal: true

require_relative 'support/coverage'

SPEC_ROOT = Pathname(__FILE__).dirname

begin
  require 'pry-byebug'
rescue LoadError
end

require 'pathname'

Dir[Pathname(__FILE__).dirname.join('support/**/*.rb').to_s].each do |file|
  require file
end

require 'dry/configurable'
require 'dry/configurable/test_interface'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.filter_run_when_matching :focus
end
