# frozen_string_literal: true

require_relative "support/coverage"
require "pathname"
require "rspec-benchmark"

SPEC_ROOT = Pathname(__FILE__).dirname

begin
  require "pry-byebug"
rescue LoadError
end

Dir[Pathname(__FILE__).dirname.join("support/**/*.rb").to_s].each do |file|
  require file
end

require "dry/configurable"
require "dry/configurable/test_interface"

RSpec.configure do |config|
  config.include RSpec::Benchmark::Matchers

  config.around do |example|
    module Test
    end

    example.run

    Object.__send__(:remove_const, :Test)
  end
end
