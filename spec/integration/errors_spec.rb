RSpec.describe Dry::Configurable do
  let(:klass) do
    Class.new do
      extend Dry::Configurable

      setting :database_url, Test::Types::Strict::String
      setting :path, Test::Types::String.default('test')
    end
  end

  context 'try to access config without configuring it first' do
    it 'raises NotConfigured' do
      expect {
        klass.config
      }.to raise_error(Dry::Configurable::NotConfiguredError)
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
        Dry::Configurable::AlreadyDefinedConfigError
      )
    end
  end
end
