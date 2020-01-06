# frozen_string_literal: true

RSpec.shared_examples 'valid test interface behavior' do
  before do
    object.enable_test_interface
    object.config.dsn = 'dsn_settings'
  end

  it 'drop settings to default' do
    expect(object.config.dsn).to eq 'dsn_settings'

    object.reset_config

    expect(object.config.dsn).to be_nil
  end
end
