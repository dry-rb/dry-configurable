# frozen_string_literal: true

RSpec.describe Dry::Configurable::Config do
  let(:klass) { Dry::Configurable::Config }
  let(:config) { klass[settings].new.define! }
  let(:settings) do
    settings = Dry::Configurable::Settings.new
    settings.add(:db, 'sqlite') { |v| "#{v}:memory" }
    settings.add(:user, 'root')
    settings.add(:pass)
    settings
  end
  let(:value_class) { Dry::Configurable::Setting }
  let(:undefined) { Dry::Configurable::Undefined }

  describe '.create' do
    it 'creates a config subclass from the given settings' do
      expect(config.class).to be < klass

      expect(config.db).to eq('sqlite:memory')
      expect(config.user).to eq('root')
      expect(config.pass).to be(nil)

      expect { config.db = 'ineedm0ar' }.to change(config, :db)
        .from('sqlite:memory')
        .to('ineedm0ar:memory')
      expect { config.user = 'whoami' }.to change(config, :user)
        .from('root')
        .to('whoami')
      expect { config.pass = 'h4xz0rz' }.to change(config, :pass)
        .from(nil)
        .to('h4xz0rz')
    end
  end

  describe '#clone' do
    subject!(:clone) { config.clone }

    it 'clones and returns the config' do
      expect(clone.db).to eq(config.db)
      expect(clone.user).to eq(config.user)
      expect(clone.pass).to eq(config.pass)
      is_expected.to_not be(config)
    end
  end

  describe '#dup' do
    subject!(:dup) { config.dup }

    it 'dups and returns the config' do
      expect(dup.db).to eq(config.db)
      expect(dup.user).to eq(config.user)
      expect(dup.pass).to eq(config.pass)
      is_expected.to_not be(config)
    end
  end

  describe '#finalize!' do
    subject!(:dup) { config.finalize! }

    it 'freezes itself and the config' do
      expect { config.user = 'whoami' }
        .to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
    end
  end

  describe '#to_h' do
    subject! { config.to_h }

    context 'without nesting' do
      it 'returns a config hash' do
        is_expected.to eq(
          db: 'sqlite:memory',
          user: 'root',
          pass: nil
        )
      end
    end

    context 'with nesting' do
      let(:nested_setting) do
        ::Dry::Configurable::Settings.new do |settings|
          settings.add(:bar, 'baz') { |v| v }
        end
      end

      let(:settings) do
        Dry::Configurable::Settings.new do |settings|
          settings.add(:db, 'sqlite') { |v| "#{v}:memory" }
          settings.add(:user, 'root')
          settings.add(:pass, undefined)
          settings.add(:foo, nested_setting)
        end
      end

      it 'returns a config hash' do
        is_expected.to eq(
          db: 'sqlite:memory',
          user: 'root',
          pass: nil,
          foo: {
            bar: 'baz'
          }
        )
      end
    end
  end

  describe '#to_hash' do
    subject! { config.to_hash }

    context 'without nesting' do
      it 'returns a config hash' do
        is_expected.to eql(
          db: 'sqlite:memory',
          user: 'root',
          pass: nil
        )
      end
    end

    context 'with nesting' do
      let(:nested_setting) do
        Dry::Configurable::Settings.new do |settings|
          settings.add(:bar, 'baz')
        end
      end

      let(:settings) do
        Dry::Configurable::Settings.new do |settings|
          settings.add(:db, 'sqlite') { |v| "#{v}:memory" }
          settings.add(:user, 'root')
          settings.add(:pass, undefined)
          settings.add(:foo, nested_setting)
        end
      end

      it 'returns a config hash' do
        is_expected.to eql(
          db: 'sqlite:memory',
          user: 'root',
          pass: nil,
          foo: {
            bar: 'baz'
          }
        )
      end
    end
  end

  describe '#[]' do
    it 'returns given setting' do
      expect(config[:db]).to eq('sqlite:memory')
      expect(config[:user]).to eq('root')
      expect(config[:pass]).to be(nil)
    end

    it 'raises an ArgumentError when setting does not exist' do
      expect { config[:unknown] }.to raise_error(
        ArgumentError, '+unknown+ is not a setting name'
      )
    end

    it 'accepts setting name as a string' do
      expect(config['user']).to eq('root')
    end
  end

  describe '#[]=' do
    it 'sets given setting' do
      expect { config[:db] = 'ineedm0ar' }.to change(config, :db)
        .from('sqlite:memory')
        .to('ineedm0ar:memory')
      expect { config[:user] = 'whoami' }.to change(config, :user)
        .from('root')
        .to('whoami')
      expect { config[:pass] = 'h4xz0rz' }.to change(config, :pass)
        .from(nil)
        .to('h4xz0rz')
    end

    it 'raises an ArgumentError when setting does not exist' do
      expect { config[:unknown] = 'unknown' }.to raise_error(
        ArgumentError, '+unknown+ is not a setting name'
      )
    end

    it 'accepts setting name as a string' do
      expect { config['user'] = 'whoami' }.to change(config, :user)
        .from('root')
        .to('whoami')
    end
  end

  describe '#update' do
    context 'shallow' do
      before do
        config.update(db: 'jdbc:sqlite', pass: 'h4xz0rz')
      end

      it 'loads values from a hash' do
        expect(config.db).to eql('jdbc:sqlite:memory')
        expect(config.user).to eql('root')
        expect(config.pass).to eql('h4xz0rz')
      end
    end

    context 'with nesting' do
      let(:nested_setting) do
        Dry::Configurable::Settings.new do |settings|
          settings.add(:bar, 'baz')
        end
      end

      let(:settings) do
        Dry::Configurable::Settings.new do |settings|
          settings.add(:db, 'sqlite') { |v| "#{v}:memory" }
          settings.add(:user, 'root')
          settings.add(:pass, undefined)
          settings.add(:foo, nested_setting)
        end
      end

      before do
        config.update(db: 'jdbc:sqlite', foo: { bar: 'qux' })
      end

      it 'returns a config hash' do
        expect(config.db).to eql('jdbc:sqlite:memory')
        expect(config.user).to eql('root')
        expect(config.pass).to be_nil
        expect(config.foo.bar).to eql('qux')
      end
    end
  end

  describe '#dup' do
    let(:copy) { config.dup }

    context 'copy after definition' do
      before do
        config.update(db: 'jdbc:sqlite', pass: 'h4xz0rz')
        copy.update(db: 'jdbc:mysql', pass: '$ekre_|_')
      end

      it 'creates a copy' do
        expect(copy).to be_defined
        expect(config.db).to eql('jdbc:sqlite:memory')
        expect(config.pass).to eql('h4xz0rz')
        expect(copy.db).to eql('jdbc:mysql:memory')
        expect(copy.pass).to eql('$ekre_|_')
      end
    end

    context 'copy before definition' do
      let(:config) { klass[settings].new }

      before do
        copy
        config.define!
        config.update(db: 'jdbc:sqlite', pass: 'h4xz0rz')
      end

      it 'creates a copy' do
        expect(copy).not_to be_defined
        expect(config.db).to eql('jdbc:sqlite:memory')
        expect(config.pass).to eql('h4xz0rz')

        copy.define!(db: 'jdbc:mysql', pass: '$ekre_|_')
        expect(copy).to be_defined
        expect(copy.db).to eql('jdbc:mysql')
        expect(copy.pass).to eql('$ekre_|_')
        expect(config.db).to eql('jdbc:sqlite:memory')
        expect(config.pass).to eql('h4xz0rz')
      end
    end
  end
end
