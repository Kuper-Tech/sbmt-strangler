# frozen_string_literal: true

describe Sbmt::Strangler::MetricTracker do
  subject(:tracker) { described_class.new(rails_controller) }

  let(:rails_controller) do
    instance_double(
      Api::StoresController,
      http_params: http_params,
      strangler_action: instance_double(
        Sbmt::Strangler::Action,
        params_tracking_allowlist: params_tracking_allowlist
      ),
      controller_path: controller_path,
      action_name: action_name
    )
  end

  let(:http_params) { {a: 123, f: "asdf"} }
  let(:params_tracking_allowlist) { ["a"] }
  let(:controller_path) { "api/stores" }
  let(:action_name) { "index" }

  shared_examples "increments Yabeda metric" do |metric_name, extra_tags = {}|
    let(:common_tags) do
      {
        params: "a",
        controller: controller_path,
        action: action_name
      }
    end

    it "increments Yabeda metric sbmt_strangler.#{metric_name}" do
      metric = ::Yabeda.sbmt_strangler.send(metric_name)
      expect(metric).to receive(:increment).with(common_tags.merge(extra_tags))
      call
    end

    context "without params_tracking_allowlist" do
      let(:params_tracking_allowlist) { nil }

      let(:common_tags) do
        {
          params: "a,f",
          controller: controller_path,
          action: action_name
        }
      end

      it "increments Yabeda metric sbmt_strangler.#{metric_name}" do
        metric = ::Yabeda.sbmt_strangler.send(metric_name)
        expect(metric).to receive(:increment).with(common_tags.merge(extra_tags))
        call
      end
    end
  end

  describe "#track_params_usage" do
    subject(:call) { tracker.track_params_usage }

    it_behaves_like "increments Yabeda metric", :params_usage
  end

  describe "#track_work_mode" do
    subject(:call) { tracker.track_work_mode("proxy") }

    it_behaves_like "increments Yabeda metric", :work_mode, {mode: "proxy"}
  end

  describe "#track_mirror_call" do
    subject(:call) { tracker.track_mirror_call(false) }

    it_behaves_like "increments Yabeda metric", :mirror_call, {success: "false"}
  end

  describe "#track_compare_call" do
    subject(:call) { tracker.track_compare_call(true) }

    it_behaves_like "increments Yabeda metric", :compare_call, {success: "true"}
  end

  describe "#track_compare_call_result" do
    subject(:call) { tracker.track_compare_call_result(false) }

    it_behaves_like "increments Yabeda metric", :compare_call_result, {value: "false"}
  end

  describe "#track_render_call" do
    subject(:call) { tracker.track_render_call(true) }

    it_behaves_like "increments Yabeda metric", :render_call, {success: "true"}
  end

  describe "#log_unallowed_params" do
    it "logs unallowed params" do
      expect(Sbmt::Strangler.logger).to receive(:log_warn).with(<<~WARN.strip).and_call_original
        Not allowed parameters in api/stores#index: ["f"]
      WARN
      tracker.log_unallowed_params
    end
  end
end
