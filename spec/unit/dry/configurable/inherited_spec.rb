# frozen_string_literal: true

RSpec.describe Dry::Configurable, '.inherited' do
  it 'copies the config' do
    parent = Class.new do
      extend Dry::Configurable

      setting :foo, 'bar'
    end

    # it's important to trigger config here because it gets
    # finalized, and we want to ensure that the child class
    # can still expand its own config with new settings
    expect(parent.config.foo).to eql('bar')

    child = Class.new(parent) do
      setting :custom, true
    end

    expect(child.config.foo).to eql('bar')
    expect(child.config.custom).to be(true)
  end
end
