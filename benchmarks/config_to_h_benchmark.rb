# frozen_string_literal: true

require "bundler/setup"

require "benchmark/ips"
require "dry/configurable"

class Base
  extend Dry::Configurable

  setting :foo
  setting :bar
  setting :baz, default: "baz"
  setting :qux, default: "qux", constructor: :upcase.to_proc

  config.bar = "bar"
end

class Sub1 < Base
  setting :quux
end

class Sub2 < Sub1
end

def name(str)
  [ENV["BENCHMARK_NAME"], str].compact.join("/")
end

Benchmark.ips do |x|
  x.warmup = 1
  x.time = 3

  x.report(name("base")) do
    Base.config.to_h
  end

  x.report(name("sub")) do
    Sub2.config.to_h
  end

  x.save! ENV["SAVE_FILE"] if ENV["SAVE_FILE"]
  x.compare!
end
