# frozen_string_literal: true

require "pathname"
require "set"

RSpec.describe Dry::Configurable::Config do
  subject(:config) do
    klass.config
  end

  let(:klass) do
    Class.new do
      extend Dry::Configurable
    end
  end

  it "is the same object in subclasses that have not been configured" do
    klass.setting :db

    subclass = Class.new(klass)

    expect(subclass.config).to be klass.config
  end

  describe "#configure" do
    it "copies the config from a parent class when called the first time" do
      klass.setting :db

      subclass = Class.new(klass)

      expect(subclass.config).to be klass.config

      subclass.configure { |c| c.db = "sqlite" }

      expect(subclass.config).not_to be klass.config
      expect(subclass.config.db).to eq "sqlite"
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

  describe "#update" do
    it "sets new config values in a flat config" do
      klass.setting :db

      klass.configure { |c| c.update(db: "sqlite") }

      expect(klass.config).to be(config)
      expect(config.db).to eql("sqlite")
    end

    it "sets new config values in a nested config" do
      klass.setting :db do
        setting :user, default: "root"
        setting :pass, default: "secret"
      end

      klass.configure { |c| c.update(db: {user: "jane", pass: "supersecret"}) }

      expect(klass.config.db.user).to eql("jane")
      expect(klass.config.db.pass).to eql("supersecret")
    end

    it "preserves the config class of the nested config" do
      config_class = Class.new(Dry::Configurable::Config)

      klass.setting :db, config_class: config_class do
        setting :user, default: "root"
        setting :pass, default: "secret"
      end

      klass.configure { |c| c.update(db: {user: "jane", pass: "supersecret"}) }

      expect(klass.config.db.user).to eql("jane")
      expect(klass.config.db.pass).to eql("supersecret")
      expect(klass.config.db).to be_an_instance_of(config_class)
    end

    it "runs constructors" do
      klass.setting :db do
        setting :user, default: "root", constructor: ->(v) { v.upcase }
        setting :sslcert, constructor: ->(v) { v&.values_at(:pem, :pass)&.join }
      end

      klass.configure { |c| c.update(db: {user: "jane", sslcert: {pem: "cert", pass: "qwerty"}}) }

      expect(klass.config.db.user).to eql("JANE")
      expect(klass.config.db.sslcert).to eql("certqwerty")
    end

    it "raises ArgumentError when setting value is not a Hash" do
      klass.setting :db do
        setting :user
      end

      expect { klass.configure { |c| c.update(db: "string") } }
        .to raise_error(ArgumentError, '"string" is not a valid setting value')
    end
  end

  describe "#to_h" do
    before do
      klass.setting :db do
        setting :user, default: "root"
        setting :pass, default: "secret"
        setting :ports, default: Set[123, 321]
      end
    end

    it "returns the values as a hash" do
      expect(klass.config.to_h).to eq(
        db: {
          user: "root",
          pass: "secret",
          ports: Set[123, 321]
        }
      )
    end
  end

  describe "#dup" do
    context "with an object" do
      it "returns a deep-copy" do
        klass = Class.new do
          include Dry::Configurable

          setting :db do
            setting :user, default: "root"
            setting :pass, default: "secret"
            setting :ports, default: Set[123]
          end
        end

        parent = Class.new(klass).new
        parent.config.db.ports << 312

        expect(parent.config.db.ports).to eql(Set[123, 312])
        expect(parent.config.dup.db.ports).to eql(Set[123, 312])

        child = Class.new(parent.class).new
        child.config.db.ports << 476

        expect(child.config.db.ports).to eql(Set[123, 476])
        expect(child.config.dup.db.ports).to eql(Set[123, 476])

        expect(klass.new.config.db.ports).to eql(Set[123])
      end

      it "returns an equal copy" do
        klass = Class.new do
          include Dry::Configurable

          setting :db do
            setting :user, default: "root"
            setting :pass, default: "secret"
            setting :ports, default: Set[123]
          end
        end

        object = klass.new

        expect(object.config.dup).to eql(object.config)
      end
    end

    context "with a class" do
      it "returns a deep-copy" do
        klass.setting :db do
          setting :user, default: "root"
          setting :pass, default: "secret"
          setting :ports, default: Set[123]
        end

        parent = Class.new(klass) do
          configure { |config| config.db.ports << 312 }
        end

        child = Class.new(parent) do
          configure { |config| config.db.ports << 476 }
        end

        expect(klass.config.db.ports).to eql(Set[123])

        expect(parent.config.db.ports).to eql(Set[123, 312])
        expect(child.config.db.ports).to eql(Set[123, 312, 476])

        expect(parent.config.dup.db.ports).to eql(Set[123, 312])
        expect(child.config.dup.db.ports).to eql(Set[123, 312, 476])
      end

      it "returns an equal copy" do
        klass = Class.new do
          extend Dry::Configurable

          setting :db do
            setting :user, default: "root"
            setting :pass, default: "secret"
            setting :ports, default: Set[123]
          end
        end

        expect(klass.config.dup).to eql(klass.config)
      end
    end
  end

  describe "#[]" do
    it "coerces name from string" do
      klass.setting :db, default: :sqlite

      expect(klass.config["db"]).to eql(:sqlite)
    end

    it "raises ArgumentError when name is not valid" do
      expect { klass.config[:hello] }.to raise_error(ArgumentError, /hello/)
    end
  end

  describe "#method_missing" do
    it "provides access to reader methods" do
      klass.setting :hello

      expect { klass.config.method(:hello) }.to_not raise_error
    end

    it "provides access to writer methods" do
      klass.setting :hello

      expect { klass.config.method(:hello=) }.to_not raise_error
    end
  end
end
