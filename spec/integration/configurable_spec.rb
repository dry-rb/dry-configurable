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
end
