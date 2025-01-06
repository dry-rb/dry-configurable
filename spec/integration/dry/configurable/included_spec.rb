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
        def initialize
          super
        end
      end
    end

    it_behaves_like "configure"

    context "required initialize parameters" do
      let(:configurable_klass) do
        Class.new do
          include Dry::Configurable
          def initialize(a, b:) # rubocop:disable Lint/UnusedMethodArgument
            super()
          end
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

  context "with deep class hierarchy" do
    let(:configurable_class) do
      Class.new do
        include Dry::Configurable
      end
    end

    it "allows subclasses also to include Dry::Configurable" do
      subclass = Class.new(configurable_class) do
        include Dry::Configurable
      end

      expect(subclass.new.config).to be_a(Dry::Configurable::Config)
    end

    it "allows subclasses to reconfigure the behavior" do
      custom_config_class_1 = Class.new(Dry::Configurable::Config) do
        def db
          "#{super}!!"
        end
      end

      custom_config_class_2 = Class.new(Dry::Configurable::Config) do
        def db
          "#{super}??"
        end
      end

      subclass_l1 = Class.new(configurable_class) do
        setting :db
      end

      subclass_l2 = Class.new(subclass_l1) do
        include Dry::Configurable(config_class: custom_config_class_1)
      end

      subclass_l3 = Class.new(subclass_l2)

      subclass_l4 = Class.new(subclass_l3) do
        include Dry::Configurable(config_class: custom_config_class_2)
      end

      obj = subclass_l2.new
      obj.config.db = "sqlite"
      expect(obj.config.db).to eq "sqlite!!"

      obj = subclass_l3.new
      obj.config.db = "postgres"
      expect(obj.config.db).to eq "postgres!!"

      obj = subclass_l4.new
      obj.config.db = "sqlite"
      expect(obj.config.db).to eq "sqlite??"
    end

    it "sets up config across multiple prepended initialize methods" do
      custom_config_class = Class.new(Dry::Configurable::Config) do
        def db
          "#{super}!!"
        end
      end

      subclass_l1 = Class.new(configurable_class) do
        setting :db

        def initialize
          super
        end
      end

      subclass_l2 = Class.new(subclass_l1) do
        def initialize
          super
          config.db = "l2_db"
        end
      end

      subclass_l3 = Class.new(subclass_l2) do
        include Dry::Configurable(config_class: custom_config_class)

        def initialize
          super
        end
      end

      obj = subclass_l3.new
      expect(obj.config.db).to eq "l2_db!!"
    end
  end
end
