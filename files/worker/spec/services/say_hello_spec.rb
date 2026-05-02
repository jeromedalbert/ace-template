require 'rails_helper'

describe SayHello do
  describe '#perform' do
    before do
      allow(Rails.logger).to receive(:info)

      SayHello.new.perform
    end

    it { expect(Rails.logger).to have_received(:info).with('Hello world!') }
  end
end
