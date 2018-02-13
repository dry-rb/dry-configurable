RSpec.describe Dry::ConfigurableV2 do
  context 'Use of processors' do
    let(:klass) do
      Class.new do
        extend Dry::ConfigurableV2

        setting :database_url, Test::Types::String.constructor { |value| "foo::#{value}" }
      end
    end

    before do
      klass.configure do
        config :database_url, 'localhost'
      end
    end

    it 'use types constructor to generate config value' do
      expect(klass.config.database_url).to eq 'foo::localhost'
    end
  end

  context 'Use of processors with default values' do
    let(:klass) do
      Class.new do
        extend Dry::ConfigurableV2

        setting :wait_time, Test::Types::Strict::Integer.constructor(&:to_i).default { 3 }
      end
    end

    it 'will use default value if no value is provided' do
      expect(klass.config.wait_time).to eq 3
    end

    it 'will use value provided' do
      klass.configure do
        config :wait_time, '34'
      end

      expect(klass.config.wait_time).to eq 34
    end
  end

  context 'Use of processors with nested configuration' do
    let(:klass) do
      Class.new do
        extend Dry::ConfigurableV2

        setting :database do
          setting :url, Test::Types::String.constructor { |value| "foo::#{value}" }
        end
      end
    end

    before do
      klass.configure do
        config :database do
          config :url, 'localhost'
        end
      end
    end

    it 'use types constructor to generate config value' do
      expect(klass.config.database.url).to eq 'foo::localhost'
    end
  end

  context 'Use of processors with nested configuration and default values' do
    let(:klass) do
      Class.new do
        extend Dry::ConfigurableV2

        setting :wait do
          setting :time, Test::Types::Strict::Integer.constructor(&:to_i).default { 3 }
        end
      end
    end

    it 'will use default value if no value is provided' do
      expect(klass.config.wait.time).to eq 3
    end

    it 'will use value provided' do
      klass.configure do
        config :wait do
          config :time, '34'
        end
      end

      expect(klass.config.wait.time).to eq 34
    end
  end
end
