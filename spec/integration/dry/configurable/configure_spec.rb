# frozen_string_literal: true

RSpec.describe Dry::Configurable, ".configure" do
  shared_context "configurable behavior" do
    before do
      klass.setting :db

      object.configure do |config|
        config.db = "postgresql"
      end
    end

    it "sets the values" do
      expect(object.config.db).to eql("postgresql")
    end
  end

  context "when extended" do
    subject(:object) do
      klass
    end

    let(:klass) do
      Class.new do
        extend Dry::Configurable
      end
    end

    include_context "configurable behavior"

    it "copies the config from a parent class when called the first time" do
      klass.setting :db

      subclass = Class.new(klass)

      expect(subclass.config).to be klass.config

      subclass.configure { |c| c.db = "sqlite" }

      expect(subclass.config).not_to be klass.config
      expect(subclass.config.db).to eq "sqlite"
    end

    it "keeps the same config in place when configured multiple times" do
      klass.setting :db

      subclass = Class.new(klass)

      subclass.configure { |c| c.db = "sqlite" }

      subclass_config_after_first_configure = subclass.config

      subclass.configure { |c| c.db = "mysql" }

      expect(subclass.config).to be subclass_config_after_first_configure
      expect(subclass_config_after_first_configure.db).to eq "mysql"
    end

    it "does not copy the config from the parent class if no values are changed" do
      klass.setting :db

      subclass = Class.new(klass)

      expect(subclass.config).to be klass.config

      subclass.configure { |c| c.db } # rubocop:disable Style/SymbolProc

      expect(subclass.config).to be klass.config
    end

    it "preserves a custom config_class when configuring in subclass" do
      config_class = Class.new(Dry::Configurable::Config)

      klass = Class.new {
        extend Dry::Configurable(config_class: config_class)

        setting :db
      }

      subclass = Class.new(klass)

      expect(subclass.config).to be_an_instance_of config_class

      subclass.configure { |c| c.db = "sqlite" }

      expect(subclass.config.db).to eq "sqlite"
      expect(subclass.config).to be_an_instance_of config_class
    end
  end

  context "when included" do
    subject(:object) do
      klass.new
    end

    let(:klass) do
      Class.new do
        include Dry::Configurable
      end
    end

    include_context "configurable behavior"

    it "defines a constructor that sets the config" do
      expect(object.config.db).to eql("postgresql")
    end
  end
end
