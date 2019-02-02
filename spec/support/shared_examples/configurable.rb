RSpec.shared_examples 'a configurable class' do
  describe 'settings' do
    context 'without default value' do
      before { klass.setting :dsn }

      it 'returns nil' do
        expect(klass.config.dsn).to be(nil)
      end
    end

    context 'with a nil default value' do
      before { klass.setting :dsn, nil }

      it 'returns the default value' do
        expect(klass.config.dsn).to be(nil)
      end
    end

    context 'with a false default value' do
      before { klass.setting :dsn, false }

      it 'returns the default value' do
        expect(klass.config.dsn).to be(false)
      end
    end

    context 'with a string default value' do
      before { klass.setting :dsn, 'sqlite:memory' }

      it 'returns the default value' do
        expect(klass.config.dsn).to eq('sqlite:memory')
      end
    end

    context 'with a hash default value' do
      before do
        klass.setting :db_config, {
          user: 'root',
          password: ''
        }
      end

      it 'returns the default value' do
        expect(klass.config.db_config).to eq(
          user: 'root',
          password: ''
        )
      end
    end

    context 'reader option' do
      context 'without passing option' do
        before { klass.setting :dsn }
        before { klass.config.dsn = 'jdbc:sqlite:memory' }

        it 'will not create a getter method' do
          expect(klass).not_to respond_to(:dsn)
        end
      end

      context 'with hash as value ' do
        before { klass.setting :dsn, { foo: 'bar' }, reader: true }

        it 'will create a getter method' do
          expect(klass.dsn).to eq(foo: 'bar')
          expect(klass).to respond_to(:dsn)
        end
      end

      context 'with option set to true' do
        before { klass.setting :dsn, 'testing', reader: true }

        it 'will create a getter method' do
          expect(klass.dsn).to eq 'testing'
          expect(klass).to respond_to(:dsn)
        end
      end

      context 'with nested configuration' do
        before do
          klass.setting :dsn, reader: true do
            setting :pool, 5
          end
        end

        it 'will create a nested getter method' do
          expect(klass.dsn.pool).to eq 5
        end
      end

      context 'with processor' do
        context 'with default value' do
          before do
            klass.setting(:dsn, 'memory', reader: true) { |dsn| "sqlite:#{dsn}" }
          end

          it 'returns the default value' do
            expect(klass.dsn).to eq('sqlite:memory')
          end
        end

        context 'without default value' do
          before do
            klass.setting(:dsn, reader: true) { |dsn| "sqlite:#{dsn}" }
          end

          it 'returns the default value' do
            expect(klass.dsn).to eq(nil)
          end
        end
      end
    end

    context 'nested configuration' do
      before do
        klass.setting :database do
          setting :dsn, 'sqlite:memory'
        end
      end

      it 'returns the default value' do
        expect(klass.config.database.dsn).to eq('sqlite:memory')
      end
    end

    context 'with processor' do
      context 'without default value' do
        before do
          klass.setting(:dsn) { |dsn| "sqlite:#{dsn}" }
        end

        it 'returns nil' do
          expect(klass.config.dsn).to be(nil)
        end
      end

      context 'with default value' do
        before do
          klass.setting(:dsn, 'memory') { |dsn| "sqlite:#{dsn}" }
        end

        it 'returns the default value' do
          expect(klass.config.dsn).to eq('sqlite:memory')
        end
      end

      context 'nested configuration' do
        before do
          klass.setting :database do
            setting(:dsn, 'memory') { |dsn| "sqlite:#{dsn}" }
          end
        end

        it 'returns the default value' do
          expect(klass.config.database.dsn).to eq('sqlite:memory')
        end
      end
    end
  end

  describe 'configuration' do
    context 'without nesting' do
      context 'without processor' do
        before do
          klass.setting :dsn, 'sqlite:memory'
        end

        before do
          klass.config.dsn = 'jdbc:sqlite:memory'
        end

        it 'updates the config value' do
          expect(klass.config.dsn).to eq('jdbc:sqlite:memory')
        end
      end

      context 'with processor' do
        before do
          klass.setting(:dsn, 'sqlite') { |dsn| "#{dsn}:memory" }
        end

        before do
          klass.config.dsn = 'jdbc:sqlite'
        end

        it 'updates the config value' do
          expect(klass.config.dsn).to eq('jdbc:sqlite:memory')
        end
      end
    end

    context 'with nesting' do
      context 'without processor' do
        before do
          klass.setting :database do
            setting :dsn, 'sqlite:memory'
          end

          klass.config.database.dsn = 'jdbc:sqlite:memory'
        end

        it 'updates the config value' do
          expect(klass.config.database.dsn).to eq('jdbc:sqlite:memory')
        end
      end

      context 'with processor' do
        before do
          klass.setting :database do
            setting(:dsn, 'sqlite') { |dsn| "#{dsn}:memory" }
          end

          klass.config.database.dsn = 'jdbc:sqlite'
        end

        it 'updates the config value' do
          expect(klass.config.database.dsn).to eq('jdbc:sqlite:memory')
        end
      end
    end

    context 'when finalized' do
      before do
        klass.setting :dsn
        klass.config.dsn = 'jdbc:sqlite'
        klass.finalize!
      end

      it 'disallows modification' do
        expect {
          klass.config.dsn = 'jdbc:sqlite'
        }.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
      end

      it 'disallows direct modification on config' do
        expect {
          klass.config.dsn = 'jdbc:sqlite:memory'
        }.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
      end
    end

    context 'when inherited' do
      context 'without processor' do
        before do
          klass.setting :dsn
          klass.config.dsn = 'jdbc:sqlite:memory'
        end

        subject(:subclass) { Class.new(klass) }

        it 'retains its configuration' do
          expect(subclass.config.dsn).to eql('jdbc:sqlite:memory')
        end

        context 'when the inherited config is modified' do
          before do
            subclass.config.dsn = 'jdbc:sqlite:file'
          end

          it 'does not modify the original' do
            expect(klass.config.dsn).to eql('jdbc:sqlite:memory')
            expect(subclass.config.dsn).to eql('jdbc:sqlite:file')
          end
        end
      end

      context 'with processor' do
        before do
          klass.setting(:dsn) { |dsn| "#{dsn}:memory" }
          klass.config.dsn = 'jdbc:sqlite'
        end

        subject!(:subclass) { Class.new(klass) }

        it 'retains its configuration' do
          expect(subclass.config.dsn).to eq('jdbc:sqlite:memory')
        end

        context 'when the inherited config is modified' do
          before do
            subclass.config.dsn = 'sqlite'
          end

          it 'does not modify the original' do
            expect(klass.config.dsn).to eq('jdbc:sqlite:memory')
            expect(subclass.config.dsn).to eq('sqlite:memory')
          end
        end
      end

      context 'when the inherited settings are modified' do
        before do
          klass.setting :dsn
          subclass.setting :db
          klass.config.dsn = 'jdbc:sqlite:memory'
        end

        subject!(:subclass) { Class.new(klass) }

        it 'does not modify the original' do
          expect(klass.settings).to_not include(:db)
        end
      end
    end
  end

  context 'Test Interface' do
    before { klass.enable_test_interface }

    describe 'reset_config' do
      before do
        klass.setting :dsn, nil
        klass.setting :pool do
          setting :size, nil
        end

        klass.config.dsn = 'sqlite:memory'
        klass.config.pool.size = 5

        klass.reset_config
      end

      it 'resets configuration to default values' do
        expect(klass.config.dsn).to be_nil
        expect(klass.config.pool.size).to be_nil
      end
    end
  end

  context 'Try to set new value after config has been created' do
    before do
      klass.setting :dsn, 'sqlite:memory'
      klass.config
    end

    it 'raise an exception' do
      expect { klass.setting :pool, 5 }.to raise_error(
        Dry::Configurable::AlreadyDefinedConfig
      )
    end
  end
end
