# frozen_string_literal: true

require 'pathname'

RSpec.describe Dry::Configurable::Config do
  subject(:config) do
    klass.config
  end

  let(:klass) do
    Class.new do
      extend Dry::Configurable
    end
  end

  describe '#to_h' do
    it 'dumps itself into a hash' do
      klass.setting :db do
        setting :user, 'root'
        setting :pass, 'secret'
      end

      expect(Hash(klass.config)).to eql(db: { user: 'root', pass: 'secret' })
    end
  end

  describe '#[]' do
    it 'raises ArgumentError when name is not valid' do
      expect { klass.config[:hello] }.to raise_error(ArgumentError, /hello/)
    end
  end

  describe '#method_missing' do
    it 'provides access to reader methods' do
      klass.setting :hello

      expect { klass.config.method(:hello) }.to_not raise_error
    end

    it 'provides access to writer methods' do
      klass.setting :hello

      expect { klass.config.method(:hello=) }.to_not raise_error
    end
  end
end
