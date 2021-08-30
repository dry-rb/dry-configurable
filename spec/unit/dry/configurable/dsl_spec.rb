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
    expect(logger.string).to match(/default value as positional argument to settings is deprecated/)
  end

  it "compiles when giving a default as positional argument, and suppresses the warning when flagged off" do
    Dry::Configurable.warn_on_setting_positional_default false

    logger = StringIO.new
    Dry::Core::Deprecations.set_logger!(logger)
    setting = dsl.setting :user, "root"

    expect(setting.name).to be(:user)
    expect(setting.value).to eql("root")
    logger.rewind
    expect(logger.string).to be_empty

    Dry::Configurable.warn_on_setting_positional_default true
  end

  it "compiles but deprecates giving a defalt hash value as a positional argument (without any keyword args)" do
    # This test is necessary for behavior specific to Ruby 2.6 and 2.7

    logger = StringIO.new
    Dry::Core::Deprecations.set_logger!(logger)

    setting = dsl.setting :default_options, {foo: "bar"}

    expect(setting.name).to be(:default_options)
    expect(setting.value).to eq(foo: "bar")
    logger.rewind
    expect(logger.string).to match(/default value as positional argument to settings is deprecated/)

    if RUBY_VERSION < "3.0"
      logger = StringIO.new
      Dry::Core::Deprecations.set_logger!(logger)

      setting = dsl.setting :default_options, foo: "bar"

      expect(setting.name).to be(:default_options)
      expect(setting.value).to eq(foo: "bar")
      logger.rewind
      expect(logger.string).to match(/default value as positional argument to settings is deprecated/)
    end
  end

  it "compiles but deprecates giving a defalt hash value as a positional argument (with keyword args)" do
    # This test is necessary for behavior specific to Ruby 2.6 and 2.7

    logger = StringIO.new
    Dry::Core::Deprecations.set_logger!(logger)
    setting = dsl.setting :default_options, {foo: "bar"}, reader: true

    expect(setting.name).to be(:default_options)
    expect(setting.value).to eq(foo: "bar")
    logger.rewind
    expect(logger.string).to match(/default value as positional argument to settings is deprecated/)
  end

  it "does not infer a default hash value when non-valid keyword arguments are mixed in with valid keyword arguments" do
    # This test is necessary for behavior specific to Ruby 2.6 and 2.7

    expect { dsl.setting :default_options, foo: "bar", reader: true }.to raise_error ArgumentError, "Invalid options: [:foo]"
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
    expect(logger.string).to match(/constructor as a block is deprecated/)
  end

  it "supports but deprecates giving a constructor as a block, and suppresses the warning when flagged off" do
    Dry::Configurable.warn_on_setting_constructor_block false

    logger = StringIO.new
    Dry::Core::Deprecations.set_logger!(logger)

    setting = dsl.setting(:dsn, default: "sqlite") { |value| "jdbc:#{value}" }

    expect(setting.name).to be(:dsn)
    expect(setting.value).to eql("jdbc:sqlite")
    logger.rewind
    expect(logger.string).to be_empty

    Dry::Configurable.warn_on_setting_constructor_block true
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
