# frozen_string_literal: true

require 'pathname'

RSpec.describe Dry::Configurable, '.setting' do
  shared_context 'configurable behavior' do
    context 'without a default value' do
      before do
        klass.setting :db
      end

      it 'sets nil as the default' do
        expect(object.config.db).to be(nil)
      end

      it 'allows configuring a setting using a writer' do
        object.config.db = 'sqlite'

        expect(object.config.db).to eql('sqlite')
      end

      it 'allows configuring a setting using a square-bracket writer' do
        object.config[:db] = 'sqlite'

        expect(object.config.db).to eql('sqlite')

        object.config[:db] = 'mariadb'

        expect(object.config.db).to eql('mariadb')
      end
    end

    it 'raises when invalid options are passed' do
      expect {
        klass.setting :db_config, { user: 'root', password: '', reader: true }
      }.to raise_error(
        ArgumentError, 'Invalid options: [:user, :password]'
      )
    end

    context 'with a default value' do
      context 'string' do
        before do
          klass.setting :db, 'sqlite'
        end

        it 'presets the default value' do
          expect(object.config.db).to eql('sqlite')
        end
      end

      context 'hash' do
        it 'returns the default value' do
          klass.setting :db_config, { user: 'root', password: '' }

          expect(object.config.db_config).to eql(user: 'root', password: '')
        end

        it 'maintains the original hash object' do
          hash = { user: 'root', password: '' }

          klass.setting :db_config, hash

          expect(object.config.db_config).to be(hash)
        end
      end
    end

    context 'with nested settings' do
      before do
        klass.setting :db do
          setting :type, 'sqlite'
          setting :cred do
            setting :user
            setting :pass
          end
        end
      end

      it 'nests values in the config' do
        expect(object.config.db.type).to eql('sqlite')
        expect(object.config.db.cred.user).to be(nil)
        expect(object.config.db.cred.pass).to be(nil)

        object.config.db.cred.user = 'root'
        object.config.db.cred.pass = 'secret'

        expect(object.config.db.cred.user).to eql('root')
        expect(object.config.db.cred.pass).to eql('secret')
      end
    end

    context 'with a value pre-processor' do
      it 'pre-processes the value with nil default' do
        klass.setting(:path, nil) { |value| "test:#{value || "fallback"}" }

        expect(object.config.path).to eql("test:fallback")

        object.configure do |config|
          config.path = 'foo'
        end

        expect(object.config.path).to eql('test:foo')
      end

      it 'pre-processes the value with undefined default' do
        klass.setting(:path) { |value| "test:#{value || "fallback"}" }

        expect(object.config.path).to be(nil)
      end

      it 'pre-processes the value with non-nil default' do
        klass.setting(:path, 'test') { |value| Pathname(value) }

        expect(object.config.path).to eql(Pathname('test'))
      end
    end

    context 'with reader: true' do
      it 'defines a reader shortcut when there is no default' do
        klass.setting :db, reader: true

        expect(object.db).to be(nil)
      end

      it 'defines a reader shortcut when there is default' do
        klass.setting :db, 'sqlite', reader: true

        expect(object.db).to eql('sqlite')
      end
    end

    context 'with a ruby keyword' do
      before do
        klass.setting :if, true
      end

      it 'works' do
        expect(object.config.if).to be(true)
      end
    end

    it 'rejects invalid names' do
      %i(foo? bar! d'oh 7 {} - ==).each do |name|
        expect { klass.setting name }.to raise_error(ArgumentError, /not a valid/)
      end
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

    context 'with a subclass' do
      let(:subclass) do
        Class.new(klass)
      end

      it 'allows defining more settings' do
        klass.setting :db, 'sqlite'

        subclass.setting :username, 'root'
        subclass.setting :password

        subclass.config.password = 'secret'

        expect(subclass.config.db).to eql('sqlite')
        expect(subclass.config.username).to eql('root')
        expect(subclass.config.password).to eql('secret')
      end

      it 'adding parent setting does not affect child' do
        klass.setting :db, 'sqlite'

        expect(subclass.settings).to eql(Set[:db])

        klass.setting :other

        expect(subclass.settings).to eql(Set[:db])
      end

      it 'configured parent copies config to the child' do
        klass.setting :db

        object.config.db = 'mariadb'

        expect(subclass.config.db).to eql('mariadb')
      end

      it 'not configured parent does not set child config' do
        klass.setting :db

        expect(subclass.config.db).to be(nil)
      end

      it 'changing child does not affect parent' do
        klass.setting :db, 'sqlite'

        klass.setting :nested do
          setting :test, 'hello'
        end

        subclass.configure do |config|
          config.db = 'postgresql'
          config.nested.test = 'woah!'
        end

        expect(klass.settings).to eql(Set[:db, :nested])
        expect(object.config.db).to eql('sqlite')
        expect(object.config.db).to eql('sqlite')
        expect(object.config.nested.test).to eql('hello')

        expect(subclass.settings).to eql(Set[:db, :nested])
        expect(subclass.config.db).to eql('postgresql')
        expect(subclass.config.nested.test).to eql('woah!')
      end

      it 'inherits readers from parent' do
        klass.setting :db, 'sqlite', reader: true

        expect(subclass.db).to eql('sqlite')
      end

      it 'defines a reader shortcut for nested config' do
        klass.setting :dsn, reader: true do
          setting :pool, 5
        end

        expect(klass.dsn.pool).to be(5)
      end
    end
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

    it 'creates config detached from the class settings' do
      klass.setting :db, 'sqlite'

      object.config.db = 'mariadb'

      expect(object.config.db).to eql('mariadb')
      expect(klass.new.config.db).to eql('sqlite')
    end

    it 'exposes `config` only at the instance-level' do
      expect(klass).to_not respond_to(:config)
    end

    it 'exposes `configure` only at the instance-level' do
      expect(klass).to_not respond_to(:configure)
    end

    it 'defines a constructor that sets the config' do
      klass.setting :db, 'sqlite'

      expect(object.config.db).to eql('sqlite')
    end

    it 'can be cloned' do
      klass.setting :env

      klass.setting :db do
        setting :user, 'root'
        setting :pass, 'secret'
      end

      object.freeze

      clone = object.clone

      expect(clone).to be_frozen

      expect(object.config.env).to be(nil)
      expect(clone.config.env).to be(nil)

      expect(object.config.db.user).to eql('root')
      expect(clone.config.db.user).to eql('root')

      object.config.env = 'production'
      object.config.db.user = 'jane'

      expect(object.config.env).to eql('production')

      expect(object.config.db.user).to eql('jane')
      expect(clone.config.db.user).to eql('root')

      expect(clone.config.db.pass).to be(object.config.db.pass)
    end

    it 'can be configured' do
      klass.setting :db, 'sqlite'

      object.configure do |config|
        config.db = 'mariadb'
      end

      expect(object.config).to be_frozen
      expect(object.config.db).to eql('mariadb')
    end

    it 'can be finalized' do
      klass.setting :db, 'sqlite'

      object.finalize!
      # becomes a no-op
      object.finalize!

      expect(object).to be_frozen
    end

    it 'defines a reader shortcut for nested config' do
      klass.setting :dsn, reader: true do
        setting :pool, 5
      end

      expect(object.dsn.pool).to be(5)
    end

    context 'Test Interface' do
      describe 'reset_config' do
        it 'resets configuration to default values' do
          klass.setting :dsn, nil

          klass.setting :pool do
            setting :size, nil
          end

          object.enable_test_interface

          object.config.dsn = 'sqlite:memory'
          object.config.pool.size = 5

          object.reset_config
          expect(object.config.dsn).to be_nil
          expect(object.config.pool.size).to be_nil
        end
      end
    end
  end
end
