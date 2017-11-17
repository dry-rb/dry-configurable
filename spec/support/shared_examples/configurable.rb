RSpec.shared_examples 'a configurable class' do
  describe Dry::Configurable do
    describe 'settings' do
      context 'without processor option' do
        context 'without default value' do
          before do
            klass.setting :dsn
          end

          it 'returns nil' do
            expect(klass.config.dsn).to be(nil)
          end
        end

        context 'with default value' do
          context 'with a nil default value' do
            before do
              klass.setting :dsn, nil
            end

            it 'returns the default value' do
              expect(klass.config.dsn).to be(nil)
            end
          end

          context 'with a false default value' do
            before do
              klass.setting :dsn, false
            end

            it 'returns the default value' do
              expect(klass.config.dsn).to be(false)
            end
          end

          context 'with a string default value' do
            before do
              klass.setting :dsn, 'sqlite:memory'
            end

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
        end

        context 'reader option' do
          context 'without passing option' do
            before do
              klass.setting :dsn
            end

            before do
              klass.configure do |config|
                config.dsn = 'jdbc:sqlite:memory'
              end
            end

            it 'will not create a getter method' do
              expect(klass.respond_to?(:dsn)).to be_falsey
            end
          end

          context 'with hash as value ' do
            before do
              klass.setting :dsn, { foo: 'bar' }, reader: true
            end

            it 'will create a getter method' do
              expect(klass.dsn).to eq(foo: 'bar')
              expect(klass.respond_to?(:dsn)).to be_truthy
            end
          end

          context 'with option set to true' do
            before do
              klass.setting :dsn, 'testing', reader: true
            end

            it 'will create a getter method' do
              expect(klass.dsn).to eq 'testing'
              expect(klass.respond_to?(:dsn)).to be_truthy
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
            klass.configure do |config|
              config.dsn = 'jdbc:sqlite:memory'
            end
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
            klass.configure do |config|
              config.dsn = 'jdbc:sqlite'
            end
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

            klass.configure do |config|
              config.database.dsn = 'jdbc:sqlite:memory'
            end
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

            klass.configure do |config|
              config.database.dsn = 'jdbc:sqlite'
            end
          end

          it 'updates the config value' do
            expect(klass.config.database.dsn).to eq('jdbc:sqlite:memory')
          end
        end
      end

      context 'when finalized' do
        before do
          klass.setting :dsn
          klass.setting :foo, 'bar'
          klass.setting :nested do
            setting :foo, 'bar'
          end
          klass.setting :deeply_nested do
            setting :foo do
              setting :bar, 'baz'
            end
          end
          klass.configure do |config|
            config.dsn = 'jdbc:sqlite'
          end
          klass.finalize!
        end

        it 'disallows modification' do
          expect do
            klass.configure do |config|
              config.dsn = 'jdbc:sqlite'
            end
          end.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
        end

        it 'disallows direct modification on config' do
          expect do
            klass.config.dsn = 'jdbc:sqlite:memory'
          end.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
        end

        it 'disallows modification of default settings' do
          expect do
            klass.configure do |config|
              config.foo = 'oops'
            end
          end.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
        end

        it 'disallows direct modification of default settings' do
          expect do
            klass.config.foo = 'oops'
          end.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
        end

        it 'disallows modification of default nested settings' do
          expect do
            klass.configure do |config|
              config.nested.configure do |nested_config|
                nested_config.foo = 'oops'
              end
            end
          end.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
        end

        it 'disallows direct modification of default nested settings' do
          expect do
            klass.config.nested.foo = 'oops'
          end.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
        end

        it 'disallows modification of default deeply nested settings' do
          expect do
            klass.configure do |config|
              config.deeply_nested.configure do |cc|
                cc.foo.configure do |c|
                  c.bar = 'oops'
                end
              end
            end
          end.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
        end

        it 'disallows direct modification of default deeply nested settings' do
          expect do
            klass.config.deeply_nested.foo.bar = 'oops'
          end.to raise_error(Dry::Configurable::FrozenConfig, 'Cannot modify frozen config')
        end
      end

      context 'when inherited' do
        context 'without processor' do
          before do
            klass.setting :dsn
            klass.configure do |config|
              config.dsn = 'jdbc:sqlite:memory'
            end
          end

          subject!(:subclass) { Class.new(klass) }

          it 'retains its configuration' do
            expect(subclass.config.dsn).to eq('jdbc:sqlite:memory')
          end

          context 'when the inherited config is modified' do
            before do
              subclass.configure do |config|
                config.dsn = 'jdbc:sqlite:file'
              end
            end

            it 'does not modify the original' do
              expect(klass.config.dsn).to eq('jdbc:sqlite:memory')
              expect(subclass.config.dsn).to eq('jdbc:sqlite:file')
            end
          end
        end

        context 'with processor' do
          before do
            klass.setting(:dsn) { |dsn| "#{dsn}:memory" }
            klass.configure do |config|
              config.dsn = 'jdbc:sqlite'
            end
          end

          subject!(:subclass) { Class.new(klass) }

          it 'retains its configuration' do
            expect(subclass.config.dsn).to eq('jdbc:sqlite:memory')
          end

          context 'when the inherited config is modified' do
            before do
              subclass.configure do |config|
                config.dsn = 'sqlite'
              end
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
            klass.configure do |config|
              config.dsn = 'jdbc:sqlite:memory'
            end
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

          klass.configure do |config|
            config.dsn = 'sqlite:memory'
            config.pool.size = 5
          end

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
end
