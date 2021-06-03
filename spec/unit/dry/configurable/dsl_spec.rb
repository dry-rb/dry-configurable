# frozen_string_literal: true

require "dry/configurable/dsl"

RSpec.describe Dry::Configurable::DSL do
  subject(:dsl) do
    Dry::Configurable::DSL.new
  end

  it "compiles a setting with no options" do
    setting = dsl.setting :user

    expect(setting.name).to be(:user)
    expect(setting.value).to be(nil)
  end

  it "compiles a setting with default" do
    setting = dsl.setting :user, default: "root"

    expect(setting.name).to be(:user)
    expect(setting.value).to eql("root")
  end

  it "compiles but deprecates giving a default as positional argument" do
    logger = StringIO.new
    Dry::Core::Deprecations.set_logger!(logger)
    setting = dsl.setting :user, "root"

    expect(setting.name).to be(:user)
    expect(setting.value).to eql("root")
    logger.rewind
    expect(logger.string).to match(/#{FileUtils.pwd}.*default value as positional argument to settings is deprecated/)
  end

  it "compiles a setting with a reader set" do
    setting = dsl.setting(:dsn, default: "sqlite", reader: true)

    expect(setting.name).to be(:dsn)
    expect(setting).to be_reader
  end

  it "compiles a setting with a default string value" do
    setting = dsl.setting(:dsn, default: "sqlite")

    expect(setting.name).to be(:dsn)
    expect(setting.value).to eql("sqlite")
  end

  it "compiles a setting with a default hash value" do
    default = {user: "root", pass: "secret"}

    setting = dsl.setting(:dsn, default: default)

    expect(setting.name).to be(:dsn)
    expect(setting.value).to eql(default)
  end

  it "compiles a setting with a constructor" do
    setting = dsl.setting(:dsn, default: "sqlite", constructor: ->(value) { "jdbc:#{value}" })

    expect(setting.name).to be(:dsn)
    expect(setting.value).to eql("jdbc:sqlite")
  end

  it "supports but deprecates giving a constructor as a block" do
    logger = StringIO.new
    Dry::Core::Deprecations.set_logger!(logger)

    setting = dsl.setting(:dsn, default: "sqlite") { |value| "jdbc:#{value}" }

    expect(setting.name).to be(:dsn)
    expect(setting.value).to eql("jdbc:sqlite")
    logger.rewind
    expect(logger.string).to match(/#{FileUtils.pwd}.*constructor as a block is deprecated/)
  end

  it "compiles a nested list of settings" do
    setting =
      dsl.setting(:db) do
        setting(:cred) do
          setting(:user)
          setting(:pass)
        end
      end

    expect(setting.name).to be(:db)
    expect(setting.value.cred.user).to be(nil)
    expect(setting.value.cred.pass).to be(nil)
  end
end
