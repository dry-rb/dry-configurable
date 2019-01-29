RSpec.describe Dry::Configurable::ArgumentParser do
  let(:undefined) { Dry::Configurable::Undefined }

  let(:parser) { Dry::Configurable::ArgumentParser.new }

  let(:value) { undefined }

  let(:options) { undefined }

  let(:block) { nil }

  let(:output) { parser.(value, options, block) }

  let(:parsed_value) { output[0] }

  let(:parsed_options) { output[1] }

  let(:parsed_processor) { output[2] }

  context 'with no args' do
    it 'returns default values' do
      expect(parsed_value).to eql(undefined)
      expect(parsed_options).to eql(reader: false)
    end
  end

  context 'with value and options' do
    context 'valid options' do
      let(:value) { 'dry-rb' }

      let(:options) do
        { reader: true }
      end

      it 'returns correct value and options' do
        expect(parsed_value).to eql('dry-rb')
        expect(parsed_options).to eql(reader: true)
      end
    end

    context 'invalid options' do
      let(:value) { 'dry-rb' }

      let(:options) do
        { writer: true }
      end

      it 'rejects unknown options' do
        expect { output }.to raise_error(ArgumentError)
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
        expect(parsed_value).to eql(db: 'dry-rb')
        expect(parsed_options).to eql(reader: true)
      end
    end

    context 'values as array' do
      let(:value) { [1, 2, 3] }

      let(:options) do
        { reader: true }
      end

      it 'returns correct values and empty options' do
        expect(parsed_value).to eql([1, 2, 3])
        expect(parsed_options).to eql(reader: true)
      end
    end
  end

  context 'with value only' do
    context 'valid options' do
      let(:value) { 'dry-rb' }

      it 'returns correct value and options' do
        expect(parsed_value).to eql('dry-rb')
        expect(parsed_options).to eql(reader: false)
      end
    end

    context 'with hash with non option key' do
      let(:value) do
        { writer: true }
      end

      it 'returns correct value and options' do
        expect(parsed_value).to eql(writer: true)
        expect(parsed_options).to eql(reader: false)
      end
    end

    context 'with hash with option key' do
      let(:value) do
        { reader: true, writer: true }
      end

      it 'rejects unknown options' do
        expect { output }.to raise_error(ArgumentError)
      end
    end
  end

  context 'with valid options only' do
    context 'valid options' do
      let(:value) do
        { reader: true }
      end

      it 'returns correct value and options' do
        expect(parsed_value).to be(undefined)
        expect(parsed_options).to eql(reader: true)
      end
    end
  end
end
