# frozen_string_literal: true

RSpec.describe Dry::Configurable::Config do
  subject(:config) { described_class.new(settings) }

  subject(:settings) {
    Class.new {
      extend Dry::Configurable

      setting :db do
        setting :user, default: "root"
        setting :options, default: {ssl: true, flags: []}
      end

      setting :redis do
        setting :url
      end
    }._settings
  }

  describe "#configure" do
    it "does nothing when the given block is empty" do
      expect { config.configure {} }.not_to change { config.hash }
    end

    it "updates assigned values only" do
      db_options_oid = config.db.options.object_id
      redis_oid = config.redis.object_id

      config.configure do |c|
        c.db.user = "jane"
      end

      expect(config.db.user).to eq "jane"

      expect(config.db.options.object_id).to eq db_options_oid
      expect(config.redis.object_id).to eq redis_oid
    end

    it "updates mutated nested values only" do
      db_user_oid = config.db.user.object_id
      db_options_flags_oid = config.db.options[:flags].object_id
      redis_oid = config.redis.object_id

      config.configure do |c|
        c.db.options[:ssl] = false
      end

      expect(config.db.options[:ssl]).to be false

      expect(config.db.user.object_id).to eq db_user_oid
      expect(config.db.options[:flags].object_id).to eq db_options_flags_oid
      expect(config.redis.object_id).to eq redis_oid
    end

    it "does not update values that have been accessed but not changed" do
      db_oid = config.db.object_id

      config.configure { |c| c.db } # rubocop:disable Style/SymbolProc

      expect(config.db.object_id).to eq db_oid
    end

    context "custom nested config classes" do
      subject(:config_class) { Class.new(Dry::Configurable::Config) }

      subject(:settings) {
        config_class = self.config_class

        Class.new {
          extend Dry::Configurable

          setting :redis, config_class: config_class do
            setting :url
          end
        }._settings
      }

      it "preserves the config class when updating values" do
        expect(config.redis).to be_an_instance_of config_class

        config.configure { |c| c.redis.url = "http://example.com" }

        expect(config.redis).to be_an_instance_of config_class
        expect(config.redis.url).to eq "http://example.com"
      end
    end
  end
end
