RSpec.describe Dry::ConfigurableV2 do
  context 'reader option' do
    let(:klass) do
      Class.new do
        extend Dry::ConfigurableV2

        setting :database_url, Test::Types::String.meta(reader: true)
      end
    end

    before do
      klass.configure do
        config :database_url,'localhost'
      end
    end

    it 'allows to access the configuration value directly' do
      expect(klass.database_url).to eq 'localhost'
    end
  end

  context 'reader option nested configuration' do
    let(:klass) do
      Class.new do
        extend Dry::ConfigurableV2

        setting :database do
          setting :url, Test::Types::String.meta(reader: true)
        end
      end
    end

    before do
      klass.configure do
        config :database do
          config :url,'localhost'
        end
      end
    end

    it 'allows to access the configuration value directly' do
      expect(klass.database.url).to eq 'localhost'
    end
  end
end
