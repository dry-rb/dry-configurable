RSpec.describe Dry::ConfigurableV2 do
  let(:klass) do
    Class.new do
      extend Dry::ConfigurableV2

      setting :database_url, Test::Types::Strict::String
      setting :path, Test::Types::String.default('test')
    end
  end

  context 'basic example' do
    before do
      klass.configure do
        config :database_url, 'jdbc:sqlite:memory'
      end
    end

    it 'allow to set values' do
      expect(klass.config.database_url).to eq 'jdbc:sqlite:memory'
    end

    it 'will use default values' do
      expect(klass.config.path).to eq 'test'
    end
  end
end
