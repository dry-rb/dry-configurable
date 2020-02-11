require 'dry/configurable/dsl'

RSpec.describe Dry::Configurable::DSL do
  subject(:dsl) do
    Dry::Configurable::DSL.new
  end

  it 'compiles a flat list of settings' do
    dsl.setting :user
    dsl.setting :pass

    settings = dsl.()

    expect(settings[:user].value).to be(nil)
    expect(settings[:pass].value).to be(nil)
  end

  it 'compiles a setting with a reader set' do
    setting = dsl.setting(:dsn, 'sqlite', reader: true)

    expect(setting).to be_reader
  end

  it 'compiles a setting with a default string value' do
    dsl.setting(:dsn, 'sqlite')

    settings = dsl.()

    expect(settings[:dsn].value).to eql('sqlite')
  end

  it 'compiles a setting with a default hash value' do
    default = { user: 'root', pass: 'secret' }

    dsl.setting(:dsn, default)

    settings = dsl.()

    expect(settings[:dsn].value).to eql(default)
  end

  it 'compiles a setting with a constructor' do
    dsl.setting(:dsn, 'sqlite') { |value| "jdbc:#{value}" }

    settings = dsl.()

    expect(settings[:dsn].value).to eql('jdbc:sqlite')
  end

  it 'compiles a nested list of settings' do
    dsl.setting :db do
      setting :cred do
        setting :user
        setting :pass
      end
    end

    settings = dsl.()

    expect(settings[:db].config.cred.user).to be(nil)
    expect(settings[:db].config.cred.pass).to be(nil)
  end
end
