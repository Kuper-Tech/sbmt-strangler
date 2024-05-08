# frozen_string_literal: true

require_relative "shared_context"

describe Sbmt::Strangler::WorkModes::Replace do
  describe "#call" do
    include_context "with work mode implemetation context"

    before do
      allow(metric_tracker).to receive(:track_mirror_call)
      allow(rails_controller).to receive(:render)
    end

    it "renders result of mirror block call" do
      expect(strangler_action.mirror).to receive(:call).with(rails_controller).and_call_original
      mode.call
      expect(rails_controller).to have_received(:render).with(mirror_result)
    end

    it "tracks mirror block call" do
      mode.call
      expect(metric_tracker).to have_received(:track_mirror_call).with(true)
    end
  end
end
