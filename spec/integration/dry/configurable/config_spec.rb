# frozen_string_literal: true

require 'pathname'
require 'set'

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
    before do
      klass.setting :db do
        setting :user, 'root'
        setting :pass, 'secret'
        setting :ports, Set[123, 321]
      end
    end

    it 'dumps itself into a hash' do
      expect(Hash(klass.config)).to eql(db: { user: 'root', pass: 'secret', ports: Set[123, 321] })
    end

    it 'is used for equality' do
      expect(klass.config).to eql(klass.config.dup)
    end
  end

  describe '#dup' do
    it 'returns a deep-copy' do
      klass.setting :db do
        setting :user, 'root'
        setting :pass, 'secret'
        setting :ports, Set[123], &:dup
      end

      subclass = Class.new(klass) do
        config.db.ports << 312
      end

      expect(klass.config.db.ports).to eql(Set[123])

      expect(subclass.config.db.ports).to eql(Set[123, 312])

      expect(subclass.config.dup.db.ports).to eql(Set[123, 312])
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
