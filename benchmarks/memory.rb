# frozen_string_literal: true

require "benchmark/memory"
require "dry/configurable"
require "dry/core/class_attributes"
require "hanami/utils/class_attribute"

def inherit_configurable(times)
  klass = Class.new do
    extend Dry::Configurable

    setting :user, default: "jane"
    setting :pass, default: "abcd"
  end

  times.times do
    _subclass = Class.new(klass)
  end
end

def inherit_configurable_nested(times)
  klass = Class.new do
    extend Dry::Configurable

    setting :db do
      setting :user, default: "jane"
      setting :pass, default: "abcd"
    end
  end

  times.times do
    _subclass = Class.new(klass)
  end
end

def inherit_dry_class_attributes(times)
  klass = Class.new do
    extend Dry::Core::ClassAttributes

    defines :user, :pass

    user "jane"
    pass "abcd"
  end

  times.times do
    _subclass = Class.new(klass)
  end
end

def inherit_hanami_class_attributes(times)
  klass = Class.new do
    include Hanami::Utils::ClassAttribute

    class_attribute :user, :pass

    self.user = "jane"
    self.pass = "abcd"
  end

  times.times do
    _subclass = Class.new(klass)
  end
end

def inherit_ordinary_class(times)
  klass = Class.new

  times.times do
    _subclass = Class.new(klass)
  end
end

times = Integer(ENV.fetch("TIMES", 100))

Benchmark.memory do |x|
  x.report("configurable") { inherit_configurable(times) }
  x.report("configurable (nested)") { inherit_configurable_nested(times) }
  x.report("dry-core class attributes") { inherit_dry_class_attributes(times) }
  x.report("hanami-utils class attributes") { inherit_hanami_class_attributes(times) }
  x.report("ordinary inheritance") { inherit_ordinary_class(times) }

  x.compare!
end
