# frozen_string_literal: true

RSpec.describe Dry::Configurable, '.included' do
  let(:configurable_klass) { Class.new.include(Dry::Configurable) }

  it 'extends ClassMethods' do
    expect(configurable_klass.singleton_class.included_modules)
      .to include(Dry::Configurable::ClassMethods)
  end

  it 'includes InstanceMethods' do
    expect(configurable_klass.included_modules)
      .to include(Dry::Configurable::InstanceMethods)
  end

  it 'raises when Dry::Configurable has already been included' do
    expect {
      configurable_klass.include(Dry::Configurable)
    }.to raise_error(Dry::Configurable::AlreadyIncluded)
  end

  it 'ensures `.config` is not defined' do
    expect(configurable_klass).not_to respond_to(:config)
  end

  it 'ensures `.configure` is not defined' do
    expect(configurable_klass).not_to respond_to(:configure)
  end
end
