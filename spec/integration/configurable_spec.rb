RSpec.describe Dry::Configurable do
  describe 'settings' do
    context 'without default value' do
      let(:configuration) do
        Class.new do
          extend Dry::Configurable

          setting :dsn
        end
      end

      it 'returns nil' do
        expect(configuration.config.dsn).to be(nil)
      end
    end

    context 'with default value' do
      let(:configuration) do
        Class.new do
          extend Dry::Configurable

          setting :dsn, 'sqlite:memory'
        end
      end

      it 'returns the default value' do
        expect(configuration.config.dsn).to eq('sqlite:memory')
      end
    end

    context 'nested configuration' do
      let(:configuration) do
        Class.new do
          extend Dry::Configurable

          setting :database do
            setting :dsn, 'sqlite:memory'
          end
        end
      end

      it 'returns the default value' do
        expect(configuration.config.database.dsn).to eq('sqlite:memory')
      end
    end
  end

  describe 'configuration' do
    context 'without nesting' do
      let(:configuration) do
        Class.new do
          extend Dry::Configurable

          setting :dsn, 'sqlite:memory'
        end
      end

      before do
        configuration.configure do |config|
          config.dsn = 'jdbc:sqlite:memory'
        end
      end

      it 'updates the config value' do
        expect(configuration.config.dsn).to eq('jdbc:sqlite:memory')
      end
    end

    context 'with nesting' do
      let(:configuration) do
        Class.new do
          extend Dry::Configurable

          setting :database do
            setting :dsn, 'sqlite:memory'
          end
        end
      end

      before do
        configuration.configure do |config|
          config.database.dsn = 'jdbc:sqlite:memory'
        end
      end

      it 'updates the config value' do
        expect(configuration.config.database.dsn).to eq('jdbc:sqlite:memory')
      end
    end
  end
end
