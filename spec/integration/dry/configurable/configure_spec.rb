# frozen_string_literal: true

RSpec.describe Dry::Configurable, '.configure' do
  shared_context 'configurable behavior' do
    before do
      klass.setting :db

      object.configure do |config|
        config.db = 'postgresql'
      end
    end

    it 'sets the values' do
      expect(object.config.db).to eql('postgresql')
    end

    it 'finalizes config' do
      expect(object.config).to be_frozen
    end
  end

  context 'when extended' do
    subject(:object) do
      klass
    end

    let(:klass) do
      Class.new do
        extend Dry::Configurable
      end
    end

    include_context 'configurable behavior'
  end

  context 'when included' do
    subject(:object) do
      klass.new
    end

    let(:klass) do
      Class.new do
        include Dry::Configurable
      end
    end

    include_context 'configurable behavior'

    it 'defines a constructor that sets the config' do
      expect(object.config.db).to eql('postgresql')
    end
  end
end
