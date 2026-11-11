# frozen_string_literal: true

require "pathname"

RSpec.describe Dry::Configurable::Config do
  subject(:config) do
    klass.config
  end

  let(:klass) do
    Class.new do
      extend Dry::Configurable
    end
  end

  describe "#configured?" do
    it "returns false if the key has not been accessed" do
      klass.setting :db
      expect(klass.config.configured?(:db)).to be false
    end

    it "returns true if the key has been assigned" do
      klass.setting :db
      klass.config.db = "sqlite"
      expect(klass.config.configured?(:db)).to be true
    end

    it "returns true when the key was assigned in a superclass" do
      klass.setting :db
      klass.config.db = "sqlite"
      subclass = Class.new(klass)
      expect(subclass.config.configured?(:db)).to be true
    end

    describe "assignable values" do
      it "returns false if the key has been read" do
        klass.setting :db
        klass.config.db
        expect(klass.config.configured?(:db)).to be false
      end

      it "returns false when the key was read in a superclass" do
        klass.setting :db
        klass.config.db
        subclass = Class.new(klass)
        expect(subclass.config.configured?(:db)).to be false
      end
    end

    describe "cloneable values" do
      it "returns false if the key has been read only" do
        klass.setting :db, cloneable: true, default: []
        klass.config.db
        expect(klass.config.configured?(:db)).to be false
      end

      it "returns false if the key was read in a superclass" do
        klass.setting :db, cloneable: true, default: []
        klass.config.db
        subclass = Class.new(klass)
        expect(subclass.config.configured?(:db)).to be false
      end

      it "returns true if the value has been mutated" do
        klass.setting :db, cloneable: true, default: []
        klass.config.db << "sqlite"
        expect(klass.config.configured?(:db)).to be true
      end

      it "returns true if the value was mutated in a superclass" do
        klass.setting :db, cloneable: true, default: []
        klass.config.db << "sqlite"
        subclass = Class.new(klass)
        expect(subclass.config.configured?(:db)).to be true
      end
    end
  end

  describe "#update" do
    it "sets new config values in a flat config" do
      klass.setting :db

      config = klass.config.update(db: "sqlite")

      expect(klass.config).to be(config)
      expect(config.db).to eql("sqlite")
    end

    it "sets new config values in a nested config" do
      klass.setting :db do
        setting :user, default: "root"
        setting :pass, default: "secret"
      end

      klass.config.update(db: {user: "jane", pass: "supersecret"})

      expect(klass.config.db.user).to eql("jane")
      expect(klass.config.db.pass).to eql("supersecret")
    end

    it "runs constructors" do
      klass.setting :db do
        setting :user, default: "root", constructor: ->(v) { v.upcase }
        setting :sslcert, constructor: ->(v) { v&.values_at(:pem, :pass)&.join }
      end

      klass.config.update(db: {user: "jane", sslcert: {pem: "cert", pass: "qwerty"}})

      expect(klass.config.db.user).to eql("JANE")
      expect(klass.config.db.sslcert).to eql("certqwerty")
    end

    it "raises ArgumentError when setting value is not a Hash" do
      klass.setting :db do
        setting :user
      end

      expect { klass.config.update(db: "string") }
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
          config.db.ports << 312
        end

        child = Class.new(parent) do
          config.db.ports << 476
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

  describe "#hash" do
    it "returns the integer hash value for the convig based on its values" do
      klass.setting :db

      expect(klass.config.hash).to be_an_instance_of(Integer)
      expect { klass.config.db = "sqlite" }.to change { klass.config.hash }
    end

    it "is memoized when the config is finalized", :performance do
      klass.setting :a
      klass.setting :b
      klass.setting :c
      klass.setting :d
      klass.setting :e

      finalized_config = klass.config.dup.finalize!

      expect(finalized_config.hash).to eq klass.config.hash
      expect { finalized_config.hash }.to perform_faster_than { klass.config.hash }.at_least(5).times
    end
  end

  describe "finalize!" do
    it "can be finalized" do
      klass.setting :db do
        setting :user, default: "root".dup
      end

      klass.finalize!
      klass.finalize! # second call becomes a no op

      # It freezes the config and nested config classes
      expect(klass.config).to be_frozen
      expect(klass.config.db).to be_frozen

      # But does not freeze values by default
      expect(klass.config.db.user).not_to be_frozen
      klass.config.db.user << "foo"
      expect(klass.config.db.user).to eq("rootfoo")

      # It does not allow configure block anymore
      expect { klass.configure {} }.to raise_error(Dry::Configurable::FrozenConfigError)
    end

    it "can be finalized with freezing values" do
      klass.setting :db do
        setting :user, default: "root".dup
      end

      klass.finalize!(freeze_values: true)
      klass.finalize!(freeze_values: true) # second call becomes a no op

      expect(klass.config).to be_frozen
      expect(klass.config.db).to be_frozen

      expect(klass.config.db.user).to be_frozen
      expect { klass.config.db.user << "foo" }.to raise_error(FrozenError)

      # does not allow configure block anymore
      expect { klass.configure {} }.to raise_error(Dry::Configurable::FrozenConfigError)
    end

    it "returns early when finalizing a second time" do
      klass.setting :db do
        setting :user, default: "root".dup
      end

      klass.finalize!
      expect(klass.config).to be_frozen
      expect(klass.config.db.user).not_to be_frozen

      # Calling the second time does not do any work
      klass.finalize!(freeze_values: true)
      expect(klass.config.db.user).not_to be_frozen
    end
  end

  describe "#to_data" do
    it "raises if the config is not finalized" do
      klass.setting :db

      expect { klass.config.to_data }.to raise_error(
        Dry::Configurable::FrozenConfigError,
        /must be finalized/
      )
    end

    it "returns a frozen Data instance with a member for every setting" do
      klass.setting :db, default: "sqlite"
      klass.setting :pool, default: 5
      klass.finalize!

      data = klass.config.to_data

      expect(data).to be_frozen
      expect(data).to be_a(Data)
      expect(data.db).to eq("sqlite")
      expect(data.pool).to eq(5)
      expect(data.members).to eq(%i[db pool])
    end

    it "converts nested configs recursively as Data instances" do
      klass.setting :db do
        setting :host, default: "localhost"
        setting :port, default: 5432
      end
      klass.finalize!

      data = klass.config.to_data

      expect(data.db).to be_a(Data)
      expect(data.db).to be_frozen
      expect(data.db.host).to eq("localhost")
      expect(data.db.port).to eq(5432)
    end

    it "returns a fresh but structurally-equal instance per call" do
      klass.setting :db, default: "sqlite"
      klass.finalize!

      first = klass.config.to_data
      second = klass.config.to_data

      expect(first).not_to equal(second)
      expect(first).to eq(second)
      expect(first).to eql(second)
      expect(first.hash).to eq(second.hash)
    end

    it "shares the underlying Data class across configs with the same schema" do
      klass.setting :db
      klass.setting :pool

      first = klass.config.dup.finalize!
      second = klass.config.dup.finalize!

      expect(first.to_data.class).to equal(second.to_data.class)
    end

    it "captures mutable values by reference (not deep-frozen by default)" do
      klass.setting :list, default: []
      klass.finalize!

      klass.config.list << "added after finalize"

      expect(klass.config.to_data.list).to eq(["added after finalize"])
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

    it "reads a setting's default, then its assigned value" do
      klass.setting :hello, default: "world"

      expect(config.hello).to eq "world"

      config.hello = "there"

      expect(config.hello).to eq "there"
    end

    it "ignores arguments given to a reader" do
      klass.setting :hello, default: "world"

      expect(config.hello(1)).to eq "world"
    end

    it "does not treat a writer called without a value as a reader" do
      klass.setting :hello, default: "world"

      config.public_send(:hello=)

      expect(config.hello).to be_nil
    end

    it "raises NoMethodError for a method that is not a setting" do
      klass.setting :hello

      expect { config.goodbye }.to raise_error(NoMethodError)
      expect { config.goodbye = 1 }.to raise_error(NoMethodError)
    end
  end
end
