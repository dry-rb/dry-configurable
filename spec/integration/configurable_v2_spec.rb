RSpec.describe Dry::ConfigurableV2 do
  context 'when extended' do
    let(:klass) do
      Class.new do
        extend Dry::ConfigurableV2

        setting :database_url, Test::Types::String
        setting :path, Test::Types::String.default('test')
      end
    end

    context 'try to access config without configuring it first' do
      it 'raises NotConfigured' do
        expect {
          klass.config
        }.to raise_error(Dry::ConfigurableV2::NotConfigured)
      end

      context 'all setting has defaults' do
        let(:klass) do
          Class.new do
            extend Dry::ConfigurableV2

            setting :database_url, Test::Types::String.default('localhost')
            setting :path, Test::Types::String.default('test')
          end
        end

        it 'returns config' do
          expect(klass.config.database_url).to eq 'localhost'
          expect(klass.config.path).to eq 'test'
        end
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

    context 'nested configuration' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

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

      context 'allow to set up processor for nested config' do
        let(:klass) do
          Class.new do
            extend Dry::ConfigurableV2

            setting :preview do
              setting(:testing, Test::Types::String) { |value| "foo::#{value}" }
            end
          end
        end

        it 'allow to set values for nested configuration' do
          klass.configure do
            config :preview do
              config :testing, 'tested'
            end
          end

          expect(klass.config.preview.testing).to eq 'foo::tested'
        end
      end
    end

    context 'processors' do
      let(:klass) do
        Class.new do
          extend Dry::ConfigurableV2

          setting(:database_url, Test::Types::String) { |value| "hello::#{value}" }
        end
      end

      it 'allow to set values using processors' do
        klass.configure do
          config :database_url, 'jdbc:sqlite:memory'
        end

        expect(klass.config.database_url).to eq 'hello::jdbc:sqlite:memory'
      end
    end

    context 'try to set new value after config has been created' do
      before do
        klass.configure do
          config :database_url, 'localhost'
        end
      end

      it 'raise an exception' do
        expect { klass.setting :pool, 5 }.to raise_error(
          Dry::ConfigurableV2::AlreadyDefinedConfig
        )
      end
    end
  end
end
