RSpec.shared_examples 'a configurable class old api' do
  describe Dry::Configurable do
    describe 'settings' do
      context 'works with old api' do
        context 'with a nil default value' do
          before do
            klass.setting :dsn
          end

          it 'returns the default value' do
            expect(klass.config.dsn).to be(nil)
          end
        end

        context 'with an array as default value' do
          let(:array) do
            []
          end
          before do
            klass.setting :words, array
          end

          it 'returns the default value' do
            expect(klass.config.words).to be(array)
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
            klass.setting :db_config, user: 'root', password: ''
          end

          it 'returns the default value' do
            expect(klass.config.db_config).to eq(
              user: 'root',
              password: ''
            )
          end
        end

        context 'with nesting' do
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

        context 'Test Interface' do
          before { klass.enable_test_interface }

          describe 'reset_config' do
            before do
              klass.setting :dsn
              klass.setting :pool do
                setting :size
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
      end
    end
  end
end
