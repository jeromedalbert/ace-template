require 'rails_helper'

describe SayHello do
  describe '#perform' do
    before do
      allow(STDOUT).to receive(:puts)

      SayHello.new.perform
    end

    it { expect(STDOUT).to have_received(:puts).with('Hello world!') }
  end
end
