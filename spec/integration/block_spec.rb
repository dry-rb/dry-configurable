RSpec.describe Dry::Configurable, 'block syntax' do
  context 'when extended' do
    let(:klass) do
      Class.new do
        extend Dry::Configurable

        setting :dsn
      end
    end

    context 'with block' do
      before do
        klass.configure do |config|
          config.dsn = 'jdbc:sqlite:memory'
        end
      end

      it 'configures a class' do
        expect(klass.config.dsn).to eql('jdbc:sqlite:memory')
      end
    end

    context 'without block' do
      it 'still works just fine' do
        expect { klass.configure }.not_to raise_error
      end
    end
  end

  context 'when inherited' do
    let(:klass) do
      klass = Class.new {
        extend Dry::Configurable

        setting :dsn
      }
      Class.new(klass)
    end

    before do
      klass.configure do |config|
        config.dsn = 'jdbc:sqlite:memory'
      end
    end

    it 'configures a class' do
      expect(klass.config.dsn).to eql('jdbc:sqlite:memory')
    end
  end
end
