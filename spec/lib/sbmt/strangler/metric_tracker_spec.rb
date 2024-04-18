# frozen_string_literal: true

describe Sbmt::Strangler::MetricTracker do
  subject(:tracker) { described_class.new(rails_controller) }

  let(:rails_controller) do
    instance_double(
      Api::StoresController,
      http_params: http_params,
      allowed_params: allowed_params,
      controller_path: controller_path,
      action_name: action_name
    )
  end

  let(:http_params) { {a: 123, f: "asdf"} }
  let(:allowed_params) { {a: 123} }
  let(:controller_path) { "api/stores" }
  let(:action_name) { "index" }

  shared_examples "increments Yabeda metric" do |metric_name, extra_tags = {}|
    let(:common_tags) do
      {
        params: allowed_params.keys.join(","),
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

  describe "#track_params_usage" do
    subject(:call) { tracker.track_params_usage }

    include_examples "increments Yabeda metric", :params_usage
  end

  describe "#track_work_mode" do
    subject(:call) { tracker.track_work_mode("proxy") }

    include_examples "increments Yabeda metric", :work_mode, {mode: "proxy"}
  end

  describe "#track_mirror_call" do
    subject(:call) { tracker.track_mirror_call(false) }

    include_examples "increments Yabeda metric", :mirror_call, {success: "false"}
  end

  describe "#track_compare_call" do
    subject(:call) { tracker.track_compare_call(true) }

    include_examples "increments Yabeda metric", :compare_call, {success: "true"}
  end

  describe "#track_compare_result" do
    subject(:call) { tracker.track_compare_result(false) }

    include_examples "increments Yabeda metric", :compare_result, {value: "false"}
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
