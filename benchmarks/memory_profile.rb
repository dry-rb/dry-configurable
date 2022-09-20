# frozen_string_literal: true

require "dry/configurable"
require "memory_profiler"

RETAIN = [] # rubocop:disable Style/MutableConstant

def inherit_only(times)
  klass = Class.new do
    extend Dry::Configurable

    setting :name
    setting :array_setting, default: %w[jane alice jen]
    setting :hash_setting, default: {"abcd" => "efgh"}
  end

  times.times do
    subclass = Class.new(klass)
    RETAIN << subclass
  end
end

def inherit_and_configure(times)
  klass = Class.new do
    extend Dry::Configurable

    setting :name
    setting :array_setting, default: %w[jane alice jen]
    setting :hash_setting, default: {"abcd" => "efgh"}
  end

  times.times do |i|
    subclass = Class.new(klass) do
      configure do |config|
        config.name = "class #{i}"
      end
    end

    RETAIN << subclass
  end
end

times = Integer(ENV.fetch("TIMES", 1))
profile = ENV.fetch("PROFILE", "inherit_and_configure")

report = MemoryProfiler.report do
  send(profile, times)
end

report.pretty_print
