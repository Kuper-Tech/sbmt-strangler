RSpec.shared_context "with work mode implemetation context" do
  subject(:mode) do
    described_class.new(
      rails_controller: rails_controller,
      strangler_action: strangler_action,
      metric_tracker: metric_tracker,
      feature_flags: feature_flags
    )
  end

  before do
    stub_const "TestController", Class.new
    Sbmt::Strangler::Builder.call!(strangler_config)
  end

  let!(:strangler_config) do
    Sbmt::Strangler::Configuration.new.tap do |cfg|
      cfg.action_controller_base_class = "Object"
      cfg.controller "test" do |ctrl|
        ctrl.action "index" do |act|
          act.mirror = ->(_rails_controller) { mirror_result }
          act.compare = ->(_origin_response_body, _mirror_result) { compare_result }
        end
      end
    end
  end

  let(:strangler_controller) { strangler_config.controllers.first }
  let(:strangler_action) { strangler_controller.actions.first }
  let(:metric_tracker) { instance_double(Sbmt::Strangler::MetricTracker) }
  let(:rails_controller) { instance_double(TestController, controller_path: "test", action_name: "index") }
  let(:feature_flags) { instance_double(Sbmt::Strangler::FeatureFlags) }

  let(:mirror_result) { "mirror_result" }
  let(:compare_result) { true }
end
