# frozen_string_literal: true

require "pathname"
require "set"

RSpec.describe Dry::Configurable::Setting do
  subject(:setting) do
    Dry::Configurable::Setting.new(:test, **options)
  end

  describe "#initialize" do
    describe "input evaluation" do
      let(:constructor) do
        # Allow constructor calls to be observed
        ctx = self
        -> val {
          ctx.instance_variable_set :@constructor_called, true
          val
        }
      end

      before do
        @constructor_called = false
      end
    end
  end

  shared_context "copying" do
    context "input defined" do
      let(:options) do
        {}
      end

      it "maintains the name" do
        expect(copy.name).to be(setting.name)
      end

      it "maintains a copy of the options" do
        expect(copy.options).to eql(setting.options)
        expect(copy.options).to_not be(setting.options)
      end
    end
  end

  describe "#dup" do
    let(:copy) do
      setting.dup
    end

    include_context "copying"
  end

  describe "#clone" do
    let(:copy) do
      setting.clone
    end

    include_context "copying"
  end
end
