# frozen_string_literal: true

RSpec.describe Dry::Configurable, "default values" do
  it "support Undefined as a default" do
    klass = Class.new do
      extend Dry::Configurable(default_undefined: true)

      setting :foo
      setting :bar, constructor: -> v { v.upcase }
      setting :baz, default: "baz", constructor: -> v { v.upcase }
      setting :qux do
        setting :quux
      end
    end

    expect(klass.config.foo).to be(Dry::Configurable::Undefined)
    expect(klass.config.bar).to be(Dry::Configurable::Undefined)
    expect(klass.config.baz).to eq "BAZ"
    expect(klass.config.qux.quux).to be(Dry::Configurable::Undefined)

    klass.configure do |config|
      config.foo = "foo"
      config.bar = "bar"
    end

    expect(klass.config.foo).to eq "foo"
    expect(klass.config.bar).to eq "BAR"
  end
end
