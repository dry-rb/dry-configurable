require 'dry/configurable/dsl'

RSpec.describe Dry::Configurable::DSL do
  subject(:dsl) do
    Dry::Configurable::DSL.new
  end

  it 'compiles a setting with no options' do
    setting = dsl.setting :user

    expect(setting.name).to be(:user)
    expect(setting.value).to be(nil)
  end

  it 'compiles a setting with default' do
    setting = dsl.setting :user, 'root'

    expect(setting.name).to be(:user)
    expect(setting.value).to eql('root')
  end

  it 'compiles a setting with a reader set' do
    setting = dsl.setting(:dsn, 'sqlite', reader: true)

    expect(setting.name).to be(:dsn)
    expect(setting).to be_reader
  end

  it 'compiles a setting with a default string value' do
    setting = dsl.setting(:dsn, 'sqlite')

    expect(setting.name).to be(:dsn)
    expect(setting.value).to eql('sqlite')
  end

  it 'compiles a setting with a default hash value' do
    default = { user: 'root', pass: 'secret' }

    setting = dsl.setting(:dsn, default)

    expect(setting.name).to be(:dsn)
    expect(setting.value).to eql(default)
  end

  it 'compiles a setting with a constructor' do
    setting = dsl.setting(:dsn, 'sqlite') { |value| "jdbc:#{value}" }

    expect(setting.name).to be(:dsn)
    expect(setting.value).to eql('jdbc:sqlite')
  end

  it 'compiles a nested list of settings' do
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
