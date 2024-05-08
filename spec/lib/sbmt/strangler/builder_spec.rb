# frozen_string_literal: true

describe Sbmt::Strangler::Builder do
  subject(:builder) { described_class.new(config) }

  let(:config) do
    Sbmt::Strangler::Configuration.new.tap do |cfg|
      cfg.action_controller_base_class = "Object"
      cfg.controller "builder_test" do |ctl|
        ctl.action "index" do |_act|
        end
      end
    end
  end

  describe "#call!" do
    after do
      Object.send(:remove_const, "BuilderTestController") # rubocop:disable RSpec/RemoveConst
    end

    let(:expected_feature_names) do
      %w[
        builder_test#index:mirror
        builder_test#index:replace
      ]
    end

    it "adds feature flags for all modes * actions" do
      expected_feature_names.each do |feature_name|
        expect(Sbmt::Strangler::Flipper).to receive(:add)
          .with(feature_name).once.ordered.and_call_original
      end
      builder.call!
      expect(Flipper.features.map(&:name)).to eq(expected_feature_names)
    end

    context "when feature flags creation failed" do
      before do
        allow_any_instance_of(Sbmt::Strangler::FeatureFlags).to receive(:add_all!)
          .and_raise("We could not find your database")
      end

      it "just logs the warning" do
        expect(Sbmt::Strangler.logger).to receive(:log_warn)
          .with(
            "Unable to add feature flags for action builder_test#index: We could not find your database",
            error_class: "RuntimeError"
          )
          .and_call_original
        expect { builder.call! }.not_to raise_error
      end
    end

    it "defines controllers with actions" do
      builder.call!
      expect(Object).to have_constant("BuilderTestController")
      expect(BuilderTestController.method_defined?(:index)).to be(true)
      expect(BuilderTestController.include?(Sbmt::Strangler::Mixin)).to be(true)
    end
  end
end
