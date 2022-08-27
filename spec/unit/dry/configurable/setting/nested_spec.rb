# frozen_string_literal: true

require "dry/configurable/setting"
require "dry/configurable/settings"

# TODO: This should probably be on Config now
RSpec.xdescribe "Dry::Configurable::Setting::Nested" do
  # subject(:setting) do
  #   Dry::Configurable::Setting::Nested.new(:db, **options)
  # end

  # shared_context "copying" do
  #   let(:options) do
  #     {input: settings}
  #   end

  #   let(:settings) do
  #     Dry::Configurable::Settings.new(
  #       [Dry::Configurable::Setting.new(:ports, input: [123])]
  #     )
  #   end

  #   it "maintains a copy of settings" do
  #     setting.value.ports << 321

  #     expect(copy.value.ports).to eql([123, 321])
  #   end
  # end

  # describe "#dup" do
  #   let(:copy) do
  #     setting.dup
  #   end

  #   include_context "copying"
  # end

  # describe "#clone" do
  #   let(:copy) do
  #     setting.clone
  #   end

  #   include_context "copying"
  # end
end
