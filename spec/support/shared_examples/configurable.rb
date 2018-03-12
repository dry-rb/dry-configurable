RSpec.shared_examples 'a configurable class' do
  describe Dry::Configurable do
    describe 'settings' do
      context 'without processor option' do
        context 'with default value' do
          context 'with a nil default value' do
            before do
              klass.setting :dsn, Test::Types::Nil.default(nil)
            end

            it 'returns the default value' do
              expect(klass.config.dsn).to be(nil)
            end
          end

          context 'with a false default value' do
            before do
              klass.setting :dsn, Test::Types::Bool.default(false)
            end

            it 'returns the default value' do
              expect(klass.config.dsn).to be(false)
            end
          end

          context 'with a string default value' do
            before do
              klass.setting :dsn,  Test::Types::String.default('sqlite:memory')
            end

            it 'returns the default value' do
              expect(klass.config.dsn).to eq('sqlite:memory')
            end
          end

          context 'with a hash default value' do
            before do
              type = Test::Types::Hash.schema(user: Test::Types::String.default('root'), password: Test::Types::String.default(''))
              klass.setting :db_config, type
            end

            it 'returns the default value' do
              skip
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
              klass.setting :dsn, Test::Types::String
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
              type = Test::Types::Hash.schema(foo: Test::Types::String.default('bar')).meta(reader: true)
              klass.setting :dsn, type
            end

            it 'will create a getter method' do
              skip
              expect(klass.dsn).to eq(foo: 'bar')
              expect(klass.respond_to?(:dsn)).to be_truthy
            end
          end

          context 'with option set to true' do
            before do
              klass.setting :dsn, Test::Types::String.default('testing').meta(reader: true)
            end

            it 'will create a getter method' do
              expect(klass.dsn).to eq 'testing'
              expect(klass.respond_to?(:dsn)).to be_truthy
            end
          end

          context 'with nested configuration' do
            before do
              klass.setting :dsn, Test::Types::Hash.meta(reader: true) do
                setting :pool, Test::Types::Integer.default(5)
              end
            end

            it 'will create a nested getter method' do
              expect(klass.dsn.pool).to eq 5
            end
          end

          context 'with processor' do
            context 'with default value' do
              before do
                type = Test::Types::String.constructor { |value| "sqlite:#{value}" }
                type = type.default { |t| t['memory'] }
                type = type.meta(reader: true)
                klass.setting(:dsn, type)
              end

              it 'returns the default value' do
                expect(klass.dsn).to eq('sqlite:memory')
              end
            end

            context 'without default value' do
              before do
                type = Test::Types::String.constructor { |value| "sqlite:#{value}" }
                type = type.meta(reader: true)
                klass.setting(:dsn, type)
              end

              it 'returns the default value' do
                skip
                expect(klass.dsn).to eq(nil)
              end
            end
          end

          context 'nested configuration' do
            before do
              klass.setting :database do
                setting :dsn, Test::Types::String.default('sqlite:memory')
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
              klass.setting(:dsn, Test::Types::String.constructor { |value| "sqlite:#{value}" })
            end

            it 'returns nil' do
              skip
              expect(klass.config.dsn).to be(nil)
            end
          end

          context 'with default value' do
            before do
              type = Test::Types::String.constructor { |value| "sqlite:#{value}" }
              type = type.default { |t| t['memory'] }
              klass.setting(:dsn, type)
            end

            it 'returns the default value' do
              expect(klass.config.dsn).to eq('sqlite:memory')
            end
          end

          context 'nested configuration' do
            before do
              type = Test::Types::String.constructor { |value| "sqlite:#{value}" }
              type = type.default { |t| t['memory'] }
              klass.setting :database do
                setting(:dsn, type)
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
              klass.setting :dsn, Test::Types::String.default('sqlite:memory')
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
              type = Test::Types::String.constructor { |value| "#{value}:memory" }
              type = type.default { |t| t['sqlite'] }
              klass.setting(:dsn, type)
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
                setting :dsn, Test::Types::String.default('sqlite:memory')
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
              type = Test::Types::String.constructor { |value| "#{value}:memory" }
              type = type.default { |t| t['sqlite'] }
              klass.setting :database do
                setting(:dsn, type)
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
            klass.setting :dsn, Test::Types::String
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
            end.to raise_error(Dry::Configurable::FrozenConfigError, 'Cannot modify frozen config')
          end
        end

        context 'when inherited' do
          context 'without processor' do
            before do
              klass.setting :dsn, Test::Types::String
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
              klass.setting(:dsn, Test::Types::String.constructor { |value| "#{value}:memory" })
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
              klass.setting :dsn, Test::Types::String
              subclass.setting :db, Test::Types::String
              klass.configure do |config|
                config.dsn = 'jdbc:sqlite:memory'
              end
            end

            subject!(:subclass) { Class.new(klass) }

            it 'does not modify the original' do
              expect(klass.config.attributes).to_not include(:db)
            end
          end
        end
      end

      context 'Test Interface' do
        before { klass.enable_test_interface }

        describe 'reset_config' do
          before do
            klass.setting :dsn, Test::Types::String
            klass.setting :pool do
              setting :size, Test::Types::Integer
            end

            klass.configure do |config|
              config.dsn = 'sqlite:memory'
              config.pool.size = 5
            end

            # klass.reset_config
          end

          it 'resets configuration to default values' do
            skip
            expect(klass.config.dsn).to be_nil
            expect(klass.config.pool.size).to be_nil
          end
        end
      end

      context 'Try to set new value after config has been created' do
        before do
          klass.setting :dsn, Test::Types::String.default('sqlite:memory')
          klass.config
        end

        it 'raise an exception' do
          expect { klass.setting :pool, 5 }.to raise_error(
            Dry::Configurable::AlreadyDefinedConfigError
          )
        end
      end
    end
  end
end
