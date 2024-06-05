# frozen_string_literal: true

require_relative "shared_context"

describe Sbmt::Strangler::WorkModes::Replace do
  describe "#call" do
    include_context "with work mode implementation context"

    before do
      # Rendering
      allow(rails_controller).to receive(:render)

      # Metrics
      allow(metric_tracker).to receive(:track_mirror_call)
      allow(metric_tracker).to receive(:track_render_call)

      # Lambdas
      allow(strangler_action.mirror).to receive(:call).and_call_original
      allow(strangler_action.render).to receive(:call).and_call_original
    end

    it "calls action.mirror lambda" do
      mode.call
      expect(strangler_action.mirror).to have_received(:call).with(rails_controller)
    end

    it "tracks action.mirror block call" do
      mode.call
      expect(metric_tracker).to have_received(:track_mirror_call).with(true)
    end

    it "calls action.render lambda" do
      mode.call
      expect(strangler_action.render).to have_received(:call).with(mirror_result)
    end

    it "tracks action.render block call" do
      mode.call
      expect(metric_tracker).to have_received(:track_render_call).with(true)
    end

    it "renders the result of render block call" do
      mode.call
      expect(rails_controller).to have_received(:render).with(render_result)
    end

    context "when action.mirror block call raised error" do
      let(:error) { RuntimeError.new("something went wrong") }

      before do
        allow(strangler_action.mirror).to receive(:call).and_raise(error)
      end

      it "renders error" do
        mode.call
        expect(rails_controller).to have_received(:render).with(
          json: {error: "Mirror lambda call failed!"},
          status: :internal_server_error
        )
      end

      it "tracks action.mirror block failure" do
        mode.call
        expect(metric_tracker).to have_received(:track_mirror_call).with(false)
      end

      it "doesn't call action.render lambda" do
        mode.call
        expect(strangler_action.render).not_to have_received(:call)
      end

      it "tracks/logs error" do
        expect(Sbmt::Strangler.error_tracker).to receive(:error).with(error)
        expect(Sbmt::Strangler.logger).to receive(:error).with(error)
        mode.call
      end
    end

    context "when action.render block call raised error" do
      let(:error) { RuntimeError.new("something went wrong") }

      before do
        allow(strangler_action.render).to receive(:call).and_raise(error)
      end

      it "renders error" do
        mode.call
        expect(rails_controller).to have_received(:render).with(
          json: {error: "Render lambda call failed!"},
          status: :internal_server_error
        )
      end

      it "tracks action.render block failure" do
        mode.call
        expect(metric_tracker).to have_received(:track_render_call).with(false)
      end

      it "tracks/logs error" do
        expect(Sbmt::Strangler.error_tracker).to receive(:error).with(error)
        expect(Sbmt::Strangler.logger).to receive(:error).with(error)
        mode.call
      end
    end
  end
end
