RSpec.describe Dry::Configurable::Config do
  let(:klass) { Dry::Configurable::Config }
  let(:config) { klass.create(settings) }
  let(:default_preprocessor) { klass::DEFAULT_PREPROCESSOR }
  let(:settings) do
    [
      value_class.new(:db, 'sqlite', ->(v) { "#{v}:memory" }, default_preprocessor),
      value_class.new(:user, 'root', ->(v) { v }, default_preprocessor),
      value_class.new(:pass, none, ->(v) { v }, default_preprocessor)
    ]
  end
  let(:value_class) { Dry::Configurable::Config::Value }
  let(:none) { value_class::NONE  }

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
        ::Dry::Configurable::NestedConfig.new do
          setting(:bar, 'baz') { |v| v }
        end.tap(&:create_config)
      end
      let(:settings) do
        [
          value_class.new(:db, 'sqlite', ->(v) { "#{v}:memory" }, default_preprocessor),
          value_class.new(:user, 'root', ->(v) { v }, default_preprocessor),
          value_class.new(:pass, none, ->(v) { v }, default_preprocessor),
          value_class.new(:foo, nested_setting, ->(v) { v }, default_preprocessor)
        ]
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
        is_expected.to eq(
          db: 'sqlite:memory',
          user: 'root',
          pass: nil
        )
      end
    end

    context 'with nesting' do
      let(:nested_setting) do
        klass.create([value_class.new(:bar, 'baz', ->(v) { v }, default_preprocessor)])
      end
      let(:settings) do
        [
          value_class.new(:db, 'sqlite', ->(v) { "#{v}:memory" }, default_preprocessor),
          value_class.new(:user, 'root', ->(v) { v }, default_preprocessor),
          value_class.new(:pass, none, ->(v) { v }, default_preprocessor),
          value_class.new(:foo, nested_setting, ->(v) { v }, default_preprocessor)
        ]
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
end
