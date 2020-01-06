# frozen_string_literal: true

RSpec.shared_examples 'a configurable class' do
  describe 'settings' do
    context 'when inherited' do
      context 'without processor' do
        before do
          klass.setting :dsn
          object.config.dsn = 'jdbc:sqlite:memory'
        end

        let(:subclass) { Class.new(klass) }

        it 'retains its configuration' do
          expect(subclass.config.dsn).to eql('jdbc:sqlite:memory')
        end

        context 'when the inherited config is modified' do
          before do
            subclass.config.dsn = 'jdbc:sqlite:file'
          end

          it 'does not modify the original' do
            expect(object.config.dsn).to eql('jdbc:sqlite:memory')
            expect(subclass.config.dsn).to eql('jdbc:sqlite:file')
          end
        end
      end

      context 'with processor' do
        before do
          klass.setting(:dsn) { |dsn| "#{dsn}:memory" }
          object.config.dsn = 'jdbc:sqlite'
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
            expect(object.config.dsn).to eq('jdbc:sqlite:memory')
            expect(subclass.config.dsn).to eq('sqlite:memory')
          end
        end
      end

      context 'when the inherited settings are modified' do
        before do
          klass.setting :dsn
          subclass.setting :db
          object.config.dsn = 'jdbc:sqlite:memory'
        end

        subject!(:subclass) { Class.new(klass) }

        it 'does not modify the original' do
          expect(klass.settings).to_not include(:db)
        end
      end

      context 'when settings nested and parent class has default value' do
        let(:klass) do
          Class.new do
            extend Dry::Configurable

            setting :nested do
              setting :thing, 'from base klass'
            end
          end
        end

        let(:subclass) do
          Class.new(klass) do
            configure do |k|
              k.nested.thing = 'from klass'
            end
          end
        end

        before do
          # instantiate config of base class
          klass.config
          # create a subclass and instantiate its config
          subclass
        end

        it 'does not modify parent class values' do
          expect(klass.config.nested.thing).to eql('from base klass')
        end
      end

      context 'redefining settings in subclasses' do
        let(:klass) do
          Class.new do
            extend Dry::Configurable

            setting :some, :parent
          end
        end

        let(:subclass) do
          Class.new(klass) do
            setting :some, :child
          end
        end

        before { subclass }

        it 'is working w/o a warning' do
          expect(klass.config.some).to be(:parent)
          expect(subclass.config.some).to be(:child)
        end
      end
    end
  end
end
