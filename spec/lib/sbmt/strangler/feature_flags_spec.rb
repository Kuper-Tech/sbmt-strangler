# frozen_string_literal: true

describe Sbmt::Strangler::FeatureFlags do
  subject(:feature_flags) { described_class.new(strangler_action:, rails_controller:) }

  let(:strangler_config) do
    Sbmt::Strangler::Configuration.new.tap do |cfg|
      cfg.controller(controller_name) do |ctrl|
        ctrl.action(action_name) do |act|
          # ...
        end
      end
    end
  end

  let(:strangler_action) { strangler_config.controllers.first.actions.first }
  let(:rails_controller) { instance_double(ActionController::Base) }

  let(:controller_name) { "this____is/test/ctrl" }
  let(:action_name) { "action_name" }
  let(:expected_feature_prefix) { "this-is-test-ctrl__action-name" }

  describe "#mirror?" do
    it "returns false" do
      expect(feature_flags.mirror?).to be(false)
    end

    context "when mirror feature flag enabled" do
      before do
        allow(::Flipper).to receive(:enabled?)
          .with("#{expected_feature_prefix}--mirror", anything)
          .and_return(true)
      end

      it "returns true" do
        expect(feature_flags.mirror?).to be(true)
      end
    end
  end

  describe "#replace?" do
    it "returns false" do
      expect(feature_flags.replace?).to be(false)
    end

    context "when replace feature flag enabled" do
      before do
        allow(::Flipper).to receive(:enabled?)
          .with("#{expected_feature_prefix}--replace", anything)
          .and_return(true)
      end

      it "returns true" do
        expect(feature_flags.replace?).to be(true)
      end
    end
  end

  describe "::add_all!" do
    it "declares mirror and replace mode feature flags" do
      expect(::Flipper).to receive(:add).with("#{expected_feature_prefix}--mirror").once.ordered
      expect(::Flipper).to receive(:add).with("#{expected_feature_prefix}--replace").once.ordered
      feature_flags.add_all!
    end
  end
end
