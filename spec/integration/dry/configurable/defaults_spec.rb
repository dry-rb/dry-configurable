# frozen_string_literal: true

RSpec.describe Dry::Configurable, "default values" do
  it "support Undefined as a default" do
    klass = Class.new do
      extend Dry::Configurable(default_undefined: true)

      setting :foo
      setting :bar, constructor: -> v { v.upcase }
      setting :baz, default: "baz", constructor: -> v { v.upcase }
    end

    expect(klass.config.foo).to be(Dry::Configurable::Undefined)
    expect(klass.config.bar).to be(Dry::Configurable::Undefined)
    expect(klass.config.baz).to eq "BAZ"
  end
end
