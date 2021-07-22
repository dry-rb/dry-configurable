# frozen_string_literal: true

require "pathname"

RSpec.describe Dry::Configurable::Settings do
  context "can be configured with another class's settings" do
    let(:klass) do
      Class.new do
        extend Dry::Configurable
      end
    end

    context "with merge" do
      let(:other_klass) do
        Class.new do
          extend Dry::Configurable
        end
      end

      it "should override fields and return a Dry::Configurable::Settings" do
        klass.setting :database do
          setting :type, "postgresql"
          setting :host, "remote"
        end

        other_klass.setting :database do
          setting :host, "localhost"
          setting :port, 54_321
        end

        settings = other_klass._settings.merge(klass._settings)

        aggregate_failures do
          expect(settings.class).to be(Dry::Configurable::Settings)
          expect(settings[:database].input.entries.size).to eql(3)
          expect(settings[:database].input[:type].default).to eql("postgresql")
          expect(settings[:database].input[:host].default).to eql("remote")
          expect(settings[:database].input[:port].default).to eql(54_321)
        end

        aggregate_failures do
          expect(other_klass.config.database.host).to eql("localhost")
          expect(other_klass.config.database.port).to eql(54_321)
          expect { other_klass.config.database.type }.to raise_error do |error|
            expect(error.class).to eql(NoMethodError)
          end
        end

        aggregate_failures do
          expect(klass.config.database.host).to eql("remote")
          expect(klass.config.database.type).to eql("postgresql")
          expect { klass.config.database.port }.to raise_error do |error|
            expect(error.class).to eql(NoMethodError)
          end
        end
      end
    end

    context "with merge!" do
      let(:other_klass) do
        Class.new do
          extend Dry::Configurable
        end
      end

      it "replaces undefined fields" do
        klass.setting :hello, "world"
        other_klass._settings.merge!(klass._settings)
        expect(other_klass.config.hello).to eql("world")
      end

      it "replaces deep fields" do
        klass.setting :database do
          setting :dsn, "localhost"
        end

        other_klass._settings.merge!(klass._settings)
        expect(other_klass.config.database.dsn).to eql("localhost")
      end

      it "throws an error if the settings aren't Dry::Configurable::Settings" do
        klass.setting :hello, "world"
        expect { other_klass._settings.merge!(klass) }.to raise_error do |error|
          expect(error.class).to be(ArgumentError)
        end
      end
    end
  end
end
