RSpec.describe Dry::Configurable do
  context 'when extended' do
    let(:klass) do
      Class.new do
        extend Dry::Configurable
      end
    end

    let(:object) { klass }

    it_behaves_like 'a configurable object'
    it_behaves_like 'a configurable class'
  end

  context 'when extended then inherited' do
    let(:base_klass) do
      Class.new do
        extend Dry::Configurable
      end
    end

    let(:klass) do
      Class.new(base_klass)
    end

    let(:object) { klass }

    it_behaves_like 'a configurable object'
    it_behaves_like 'a configurable class'
  end

  context 'when included' do
    let(:klass) do
      Class.new do
        include Dry::Configurable
      end
    end

    let(:object) { klass.new }

    it_behaves_like 'a configurable object'

    describe 'shallow config' do
      before do
        klass.setting :dsn
      end

      it 'allows to configure class instances' do
        obj = klass.new
        expect(obj.config.dsn).to be_nil
        obj.config.dsn = 'jdbc:sqlite:memory'
        expect(obj.config.dsn).to eql('jdbc:sqlite:memory')
      end
    end

    context 'with inheritance and custom constructor in child class' do
      let(:base_klass) do
        Class.new do
          include Dry::Configurable
        end
      end

      let(:klass) do
        Class.new(base_klass) do
          setting :dsn

          def initialize(value)
            super()

            self.config.dsn = value
          end
        end
      end

      it 'allows to configure class instances' do
        obj = klass.new('jdbc:sqlite:memory')
        expect(obj.config.dsn).to eql('jdbc:sqlite:memory')
      end
    end

    context 'with a constructor in the base class' do
      let(:base_klass) do
        Class.new do
          attr_reader :foo

          def initialize(foo)
            @foo = foo
          end
        end
      end

      let(:klass) do
        Class.new(base_klass) do
          include Dry::Configurable

          setting :dsn
        end
      end

      it 'allows to configure class instances' do
        obj = klass.new(:foo)
        expect(obj.foo).to eql(:foo)
        expect(obj.config.dsn).to be_nil
      end
    end
  end
end
