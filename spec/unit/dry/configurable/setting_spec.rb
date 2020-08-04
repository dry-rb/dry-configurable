# frozen_string_literal: true

require 'pathname'
require 'set'

RSpec.describe Dry::Configurable::Setting do
  subject(:setting) do
    Dry::Configurable::Setting.new(:test, **options)
  end

  describe '#initialize' do
    describe 'input evaluation' do
      context 'input defined' do
        let(:options) do
          { input: 1 }
        end

        it 'evaluates the input' do
          expect(setting).to be_evaluated
        end

        context 'with constructor' do
          let(:options) do
            { input: 1, constructor: described_class::DEFAULT_CONSTRUCTOR }
          end
          it 'does not evaluates the input' do
            expect(setting).not_to be_evaluated
          end
        end
      end

      context 'input not defined' do
        let(:options) do
          {}
        end
        it 'does not evaluates the input' do
          expect(setting).not_to be_evaluated
        end
      end
    end
  end

  describe '#input_defined?' do
    context 'no input provided' do
      let(:options) do
        {}
      end

      it 'is false' do
        expect(setting.input_defined?).to be false
      end
    end

    context 'input provided' do
      let(:options) do
        {input: 1}
      end

      it 'is true' do
        expect(setting.input_defined?).to be true
      end
    end

    context 'default provided' do
      let(:options) do
        {default: 1}
      end

      it 'is true' do
        expect(setting.input_defined?).to be true
      end
    end
  end

  describe '#value' do
    context 'with no default' do
      let(:options) do
        {}
      end

      it 'returns nil' do
        expect(setting.value).to be(nil)
      end
    end

    context 'with no default and a constructor' do
      let(:options) do
        { constructor: -> value { value + 1 } }
      end

      it 'returns constructed value' do
        expect(setting.with(input: 1).value).to eql(2)
      end
    end

    context 'with a default value and a constructor' do
      let(:options) do
        { default: 'hello', constructor: -> value { value.to_sym } }
      end

      it 'returns default processed by the constructor' do
        expect(setting.value).to eql(:hello)
      end
    end
  end

  describe '#evaluated?' do
    context 'input defined' do
      let(:options) do
        {input: 2}
      end

      it 'is true' do
        expect(setting).to be_evaluated
      end
    end

    context 'input not defined' do
      let(:options) do
        {}
      end

      it 'is false' do
        expect(setting).not_to be_evaluated
      end

      it 'becomes true after accessing the value' do
        expect { setting.value }
          .to change { setting.evaluated? }
          .from(false)
          .to(true)
      end
    end
  end

  context '#with' do
    let(:options) do
      {}
    end

    it 'returns a new instance with a new input' do
      expect(setting.with(input: 'hello').value).to eql('hello')
    end

    it 'returns a new instance with a new default' do
      expect(setting.with(default: 'hello').value).to eql('hello')
    end

    it 'returns a new instance with a preserved value' do
      hello = setting.with(input: ['hello'])

      hello.value << 'world'

      expect(hello.with(reader: true).value).to eql(['hello', 'world'])
    end
  end

  shared_context 'copying' do
    context 'input defined' do
      let(:options) do
        { input: 'hello' }
      end

      before do
        setting.value
      end

      it 'maintains the name' do
        expect(copy.name).to be(setting.name)
      end

      it 'maintains a copy of the options' do
        expect(copy.options).to eql(setting.options)
        expect(copy.options).to_not be(setting.options)
      end

      context 'with a clonable value' do
        let(:options) do
          { input: [1, 2, 3] }
        end

        it 'maintains a copy of the value' do
          expect(copy.value).to eql(setting.value)
          expect(copy.value).to_not be(setting.value)
        end
      end

      context 'with a non-clonable value' do
        let(:options) do
          { input: :hello }
        end

        it 'maintains the original value' do
          expect(copy.value).to be(setting.value)
        end
      end
    end

    context 'input undefined' do
      let(:options) do
        # This constructor would crash if setting was evaluated when copied
        {constructor: -> value {  value + 1 } }
      end

      it 'leaves input undefined' do
        expect(copy.input_defined?).to be false
      end

      it 'does not evaluate the setting' do
        expect(copy).not_to be_evaluated
      end
    end
  end

  describe '#dup' do
    let(:copy) do
      setting.dup
    end

    include_context 'copying'
  end

  describe '#clone' do
    let(:copy) do
      setting.clone
    end

    include_context 'copying'
  end
end
