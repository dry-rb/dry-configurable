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

  describe '#update' do
    it 'sets new config values in a flat config' do
      klass.setting :db

      config = klass.config.update(db: 'sqlite')

      expect(klass.config).to be(config)
      expect(config.db).to eql('sqlite')
    end

    it 'sets new config values in a nested config' do
      klass.setting :db do
        setting :user, 'root'
        setting :pass, 'secret'
      end

      klass.config.update(db: { user: 'jane', pass: 'supersecret' })

      expect(klass.config.db.user).to eql('jane')
      expect(klass.config.db.pass).to eql('supersecret')
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

    it 'is used for equality' do
      expect(klass.config).to eql(klass.config.dup)
    end
  end

  describe '#dup' do
    context 'with a class' do
      it 'returns a deep-copy' do
        klass = Class.new do
          include Dry::Configurable

          setting :db do
            setting :user, 'root'
            setting :pass, 'secret'
            setting :ports, Set[123]
          end
        end

        parent = Class.new(klass).new
        parent.config.db.ports << 312

        expect(parent.config.db.ports).to eql(Set[123, 312])
        expect(parent.config.dup.db.ports).to eql(Set[123, 312])

        child = Class.new(parent.class).new
        child.config.db.ports << 476

        expect(child.config.db.ports).to eql(Set[123, 476])
        expect(child.config.dup.db.ports).to eql(Set[123, 476])

        expect(klass.new.config.db.ports).to eql(Set[123])
      end
    end

    context 'with an object' do
      it 'returns a deep-copy' do
        klass.setting :db do
          setting :user, 'root'
          setting :pass, 'secret'
          setting :ports, Set[123]
        end

        parent = Class.new(klass) do
          config.db.ports << 312
        end

        child = Class.new(parent) do
          config.db.ports << 476
        end

        expect(klass.config.db.ports).to eql(Set[123])

        expect(parent.config.db.ports).to eql(Set[123, 312])
        expect(child.config.db.ports).to eql(Set[123, 312, 476])

        expect(parent.config.dup.db.ports).to eql(Set[123, 312])
        expect(child.config.dup.db.ports).to eql(Set[123, 312, 476])
      end
    end
  end

  describe '#[]' do
    it 'coerces name from string' do
      klass.setting :db, :sqlite

      expect(klass.config['db']).to eql(:sqlite)
    end

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
