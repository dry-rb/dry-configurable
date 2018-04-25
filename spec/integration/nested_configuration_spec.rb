RSpec.describe Dry::Configurable do
  context 'nested configuration' do
    let(:klass) do
      Class.new do
        extend Dry::Configurable

        setting :database_url, Test::Types::String

        setting :preview do
          setting :testing, Test::Types::String
        end
      end
    end

    it 'allow to set values for nested configuration' do
      klass.configure do
        config :preview do
          config :testing, 'tested'
        end

        config :database_url, 'localhost'
      end

      expect(klass.config.preview.testing).to eq 'tested'
    end
  end

  context 'big nested configuration' do
    let(:klass) do
      Class.new do
        extend Dry::Configurable

        setting :preview do
          setting :testing do
            setting :allowed, Test::Types::Bool
          end
        end
      end
    end

    it 'allow to set values for nested configuration' do
      klass.configure do
        config :preview do
          config :testing do
            config :allowed, true
          end
        end
      end

      expect(klass.config.preview.testing.allowed).to eq true
    end
  end
end
