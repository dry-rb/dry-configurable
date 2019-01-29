RSpec.describe Dry::Configurable do
  context 'when extended' do
    let(:klass) do
      Class.new do
        extend Dry::Configurable
      end
    end

    it_behaves_like 'a configurable class'
  end

  context 'when extended then inherited' do
    let(:base_klass) do
      Class.new do
        extend Dry::Configurable
      end
    end

    let(:klass) do
      Class.new(base_klass)
    end

    it_behaves_like 'a configurable class'
  end

  context 'when included' do
    let(:klass) do
      Class.new do
        include Dry::Configurable
      end
    end

    describe 'shallow config' do
      before do
        klass.setting :dsn
      end

      it 'allows to configure class instances' do
        obj = klass.new
        expect(obj.config.dsn).to be_nil
        obj.config.dsn = 'jdbc:sqlite:memory'
        expect(obj.config.dsn).to eql('jdbc:sqlite:memory')
      end
    end
  end
end
