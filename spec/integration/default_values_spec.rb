RSpec.describe Dry::Configurable do
  context 'all setting has defaults' do
    let(:klass) do
      Class.new do
        extend Dry::Configurable

        setting :database_url, Test::Types::String.default('localhost')
        setting :path, Test::Types::String.default('test')
      end
    end

    it 'returns config' do
      expect(klass.config.database_url).to eq 'localhost'
      expect(klass.config.path).to eq 'test'
    end
  end

  context 'all nested settings has default values' do
    let(:klass) do
      Class.new do
        extend Dry::Configurable

        setting :database do
          setting :url, Test::Types::String.default('localhost')
          setting :name do
            setting :secret, Test::Types::String.default('dry-rb RULES!')
          end
        end
      end
    end

    it 'returns config' do
      expect(klass.config.database.url).to eq 'localhost'
      expect(klass.config.database.name.secret).to eq 'dry-rb RULES!'
    end
  end
end
