# frozen_string_literal: true

RSpec.describe Dry::Configurable, ".included" do
  shared_examples "configure" do
    it "extends ClassMethods" do
      expect(configurable_klass.singleton_class.included_modules)
        .to include(Dry::Configurable::ClassMethods)
    end

    it "includes InstanceMethods" do
      expect(configurable_klass.included_modules)
        .to include(Dry::Configurable::InstanceMethods)
    end

    it "raises when Dry::Configurable has already been included" do
      expect {
        configurable_klass.include(Dry::Configurable)
      }.to raise_error(Dry::Configurable::AlreadyIncludedError)
    end

    it "ensures `.config` is not defined" do
      expect(configurable_klass).not_to respond_to(:config)
    end

    it "ensures `.configure` is not defined" do
      expect(configurable_klass).not_to respond_to(:configure)
    end

    it "ensures `#config` returns instance of Dry::Configurable::Config" do
      expect(configurable_klass.new.config).to be_a(Dry::Configurable::Config)
    end
  end

  let(:configurable_klass) { Class.new.include(Dry::Configurable) }

  it_behaves_like "configure"

  context "when #initialize is defined in configurable class" do
    let(:configurable_klass) do
      Class.new do
        include Dry::Configurable
        def initialize; end
      end
    end

    it_behaves_like "configure"

    context "required initialize parameters" do
      let(:configurable_klass) do
        Class.new do
          include Dry::Configurable
          def initialize(a, b:); end
        end
      end

      it "passes the arguments through" do
        expect(configurable_klass.new("a", b: "c").config).to be_a(Dry::Configurable::Config)
      end
    end
  end

  context "when #finalize! is defined in configurable class" do
    let(:instance) do
      Class.new do
        include Dry::Configurable

        attr_accessor :finalized

        def finalize!
          @finalized = true
        end
      end.new
    end

    it "calls finalize! in configurable class" do
      instance.finalize!
      expect(instance.finalized).to be(true)
    end
  end
end
