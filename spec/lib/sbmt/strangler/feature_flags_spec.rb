# frozen_string_literal: true

describe Sbmt::Strangler::FeatureFlags do
  subject(:feature_flags) { described_class.new(strangler_action:, rails_controller:) }

  let(:strangler_config) do
    Sbmt::Strangler::Configuration.new.tap do |cfg|
      cfg.controller(controller_name) do |ctrl|
        ctrl.action(action_name) do |act|
          act.flipper_actor = ->(_http_params, _headers) { flipper_actor_result }
        end
      end
    end
  end

  let(:strangler_action) { strangler_config.controllers.first.actions.first }
  let(:rails_controller) do
    instance_double(
      Class.new(ActionController::Base) do # rubocop:disable Rails/ApplicationController
        include Sbmt::Strangler::Mixin
      end,
      http_params: ctrl_http_params,
      request: ctrl_request
    )
  end

  let(:controller_name) { "this____is/test/ctrl" }
  let(:action_name) { "action_name" }
  let(:flipper_actor_result) { nil }
  let(:expected_feature_prefix) { "this-is-test-ctrl__action-name" }

  let(:ctrl_http_params) { instance_double(Hash) }
  let(:ctrl_request) { instance_double(ActionDispatch::Request, headers: ctrl_request_headers) }
  let(:ctrl_request_headers) { instance_double(ActionDispatch::Http::Headers) }

  before do
    allow(strangler_action.flipper_actor).to receive(:call).with(ctrl_http_params, ctrl_request_headers).and_call_original
  end

  shared_examples "with actor" do
    context "with actor" do
      let(:flipper_actor_result) { "actor" }

      it("returns false") { expect(result).to be(false) }

      context "when FF enabled for actor" do
        let(:enabled_actor) { "actor" }

        before do
          allow(::Flipper).to receive(:enabled?).and_call_original

          flipper_id_struct = Sbmt::Strangler::Flipper::FLIPPER_ID_STRUCT.new(enabled_actor)
          allow(::Flipper).to receive(:enabled?)
            .with(expected_feature_name, flipper_id_struct)
            .and_return(true)
        end

        it("returns true") { expect(result).to be(true) }

        context "when enabled for another actor" do
          let(:enabled_actor) { "another_actor" }

          it("returns false") { expect(result).to be(false) }
        end
      end
    end
  end

  shared_examples "with multiple actors" do
    context "with multiple actors" do
      let(:flipper_actor_result) { ["first_actor", "second_actor"] }

      it("returns false") { expect(result).to be(false) }

      context "when FF enabled for some actors" do
        before do
          enabled_actors.each do |enabled_actor|
            flipper_id_struct = Sbmt::Strangler::Flipper::FLIPPER_ID_STRUCT.new(enabled_actor)
            Flipper.enable(expected_feature_name, flipper_id_struct)
          end
        end

        after do
          Flipper.disable(expected_feature_name)
        end

        context "when enabled for first actor" do
          let(:enabled_actors) { ["first_actor"] }

          it("returns true") { expect(result).to be(true) }
        end

        context "when enabled for second actor" do
          let(:enabled_actors) { ["second_actor"] }

          it("returns true") { expect(result).to be(true) }
        end

        context "when enabled for first and second actors" do
          let(:enabled_actors) { ["first_actor", "second_actor"] }

          it("returns true") { expect(result).to be(true) }
        end

        context "when enabled for third actor" do
          let(:enabled_actors) { ["third_actor"] }

          it("returns false") { expect(result).to be(false) }
        end
      end
    end
  end

  shared_examples "without actor" do
    context "without actor" do
      it("returns false") { expect(result).to be(false) }

      context "when feature flag enabled" do
        before do
          allow(::Flipper).to receive(:enabled?)
            .with(expected_feature_name)
            .and_return(true)
        end

        it("returns true") { expect(result).to be(true) }
      end
    end
  end

  describe "#mirror?" do
    subject(:result) { feature_flags.mirror? }

    let(:expected_feature_name) { "#{expected_feature_prefix}--mirror" }

    include_context "with actor"
    include_context "without actor"
    include_context "with multiple actors"
  end

  describe "#replace?" do
    subject(:result) { feature_flags.replace? }

    let(:expected_feature_name) { "#{expected_feature_prefix}--replace" }

    include_context "with actor"
    include_context "without actor"
    include_context "with multiple actors"
  end

  describe "::add_all!" do
    it "declares mirror and replace mode feature flags" do
      expect(::Flipper).to receive(:add).with("#{expected_feature_prefix}--mirror").once.ordered
      expect(::Flipper).to receive(:add).with("#{expected_feature_prefix}--replace").once.ordered
      feature_flags.add_all!
    end
  end
end
