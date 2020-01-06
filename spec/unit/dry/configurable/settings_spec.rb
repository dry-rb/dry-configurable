# frozen_string_literal: true

RSpec.describe Dry::Configurable::Settings do
  subject(:settings) { described_class.new }

  let(:setting_class) { Dry::Configurable::Setting }

  let(:undefined) { Dry::Configurable::Undefined }

  describe '#names' do
    context 'later-added settings' do
      before do
        settings.add(:foo)
      end

      it 'returns setting names' do
        expect(settings.names).to eql(Set.new([:foo]))
      end
    end

    context 'with passed settings' do
      let(:setting) { setting_class.new(:foo, undefined, :itself.to_proc) }

      subject(:settings) { described_class.new([setting]) }

      it 'returns setting names' do
        expect(settings.names).to eql(Set.new([:foo]))
      end
    end
  end
end
