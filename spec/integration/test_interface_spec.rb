RSpec.describe Dry::Configurable::TestInterface do
  context "when configurable class" do
    let(:klass) do
      Class.new do
        extend Dry::Configurable

        setting :dsn
      end
    end

    let(:object) { klass }

    it_behaves_like 'valid test interface behavior'
  end

  context "when configurable module" do
    let(:modulle) do
      Module.new do
        extend Dry::Configurable

        setting :dsn
      end
    end

    let(:object) { modulle }

    it_behaves_like 'valid test interface behavior'
  end

  context "when configurable instance" do
    let(:klass) do
      Class.new do
        include Dry::Configurable

        setting :dsn
      end
    end

    let(:object) { klass.new }

    it_behaves_like 'valid test interface behavior'
  end
end
