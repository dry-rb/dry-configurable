RSpec.shared_examples 'a configurable class' do
  describe Dry::Configurable do
    describe 'settings' do
      context 'without default value' do
        before do
          klass.setting :dsn
        end

        it 'returns nil' do
          expect(klass.config.dsn).to be(nil)
        end
      end

      context 'with default value' do
        before do
          klass.setting :dsn, 'sqlite:memory'
        end

        it 'returns the default value' do
          expect(klass.config.dsn).to eq('sqlite:memory')
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

    describe 'configuration' do
      context 'without nesting' do
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

      context 'when inherited' do
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
          end
        end

        context 'when the inherited settings are modified' do
          before do
            subclass.setting :db
          end

          it 'does not modify the original' do
            expect(klass._settings.keys).to_not include(:db)
          end
        end
      end
    end
  end
end
