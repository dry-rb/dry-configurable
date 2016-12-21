RSpec.describe Dry::Configurable::Config::Value do
  let(:klass) { Dry::Configurable::Config::Value }
  let(:config) { klass.new(name, value, processor) }
  let(:name) { :db }
  let(:value) { 'test' }
  let(:processor) { ->(v) { v }}

  describe '#initialize' do
    it 'coerces string name to symbol' do
      config = klass.new('db', value, processor)

      expect(config.name).to eq(:db)
    end
  end

  describe '#name' do
    subject! { config.name }

    it { is_expected.to eq(name) }
  end

  describe '#value' do
    subject! { config.value }

    context 'when value is not NONE' do
      it { is_expected.to eq(value) }
    end

    context 'when value is NONE' do
      let(:value) { klass::NONE }

      it { is_expected.to be(nil) }
    end
  end

  describe '#processor' do
    subject! { config.processor }

    it { is_expected.to eq(processor) }
  end

  describe '#none?' do
    subject! { config.none? }

    context 'when value is not NONE' do
      it { is_expected.to be(false) }
    end

    context 'when value is NONE' do
      let(:value) { klass::NONE }

      it { is_expected.to be(true) }
    end
  end
end
