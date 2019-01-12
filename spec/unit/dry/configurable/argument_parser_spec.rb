RSpec.describe Dry::Configurable::ArgumentParser do
  let(:klass) { Dry::Configurable::ArgumentParser }

  context 'with no args' do
    let(:parsed) { klass.new([]) }

    it 'return default values' do
      expect(parsed.value).to eq nil
      expect(parsed.options).to eq({})
    end
  end

  context 'with value and options' do
    let(:parsed) { klass.new([value, options]) }

    context 'valid options' do
      let(:value) { 'dry-rb' }
      let(:options) do
        { reader: true }
      end

      it 'returns correct value and options' do
        expect(parsed.value).to eq 'dry-rb'
        expect(parsed.options).to eq(reader: true)
      end
    end

    context 'invalid options' do
      let(:value) { 'dry-rb' }
      let(:options) do
        { writer: true }
      end

      it 'returns correct values and empty options' do
        expect(parsed.value).to eq 'dry-rb'
        expect(parsed.options).to eq({})
      end
    end

    context 'values as hash' do
      let(:value) do
        { db: 'dry-rb' }
      end
      let(:options) do
        { reader: true }
      end

      it 'returns correct values and empty options' do
        expect(parsed.value).to eq(db: 'dry-rb')
        expect(parsed.options).to eq(reader: true)
      end
    end

    context 'values as array' do
      let(:value) { [1, 2, 3] }
      let(:options) do
        { reader: true }
      end

      it 'returns correct values and empty options' do
        expect(parsed.value).to eq([1, 2, 3])
        expect(parsed.options).to eq(reader: true)
      end
    end
  end

  context 'with value only' do
    let(:parsed) { klass.new([value]) }
    context 'valid options' do
      let(:value) { 'dry-rb' }

      it 'returns correct value and options' do
        expect(parsed.value).to eq 'dry-rb'
        expect(parsed.options).to eq({})
      end
    end

    context 'with hash with non option key' do
      let(:value) do
        { writer: true }
      end

      it 'returns correct value and options' do
        expect(parsed.value).to eq(writer: true)
        expect(parsed.options).to eq({})
      end
    end

    context 'with hash with option key' do
      let(:value) do
        { reader: true, writer: true }
      end

      it 'returns correct value and options' do
        expect(parsed.value).to eq nil
        expect(parsed.options).to eq(reader: true)
      end
    end
  end

  context 'with options only' do
    let(:parsed) { klass.new([options]) }
    context 'valid options' do
      let(:options) do
        { reader: true }
      end

      it 'returns correct value and options' do
        expect(parsed.value).to eq nil
        expect(parsed.options).to eq(reader: true)
      end
    end
  end
end
