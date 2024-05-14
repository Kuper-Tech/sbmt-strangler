# frozen_string_literal: true

module Sbmt
  module Strangler
    class MetricTracker
      attr_reader :rails_controller

      def initialize(rails_controller)
        @rails_controller = rails_controller
      end

      def track_params_usage
        ::Yabeda.sbmt_strangler.params_usage.increment(common_tags)
      end

      def log_unallowed_params
        unallowed_params = all_request_params - allowed_request_params
        Sbmt::Strangler.logger.log_warn(<<~WARN.strip) if unallowed_params.any?
          Not allowed parameters in #{controller_path}##{action_name}: #{unallowed_params}
        WARN
      end

      def track_work_mode(mode)
        yabeda_tags = common_tags.merge(mode: mode.to_s)
        ::Yabeda.sbmt_strangler.work_mode.increment(yabeda_tags)
      end

      def track_mirror_call(success)
        yabeda_tags = common_tags.merge(success: success.to_s)
        ::Yabeda.sbmt_strangler.mirror_call.increment(yabeda_tags)
      end

      def track_compare_call(success)
        yabeda_tags = common_tags.merge(success: success.to_s)
        ::Yabeda.sbmt_strangler.compare_call.increment(yabeda_tags)
      end

      def track_compare_call_result(value)
        yabeda_tags = common_tags.merge(value: value.to_s)
        ::Yabeda.sbmt_strangler.compare_call_result.increment(yabeda_tags)
      end

      private

      delegate :http_params, :allowed_params, :controller_path, :action_name, to: :rails_controller

      def common_tags
        {
          params: allowed_request_params.join(","),
          controller: controller_path,
          action: action_name
        }
      end

      def allowed_request_params
        @allowed_request_params ||= allowed_params.keys.map(&:to_s).sort.uniq
      end

      def all_request_params
        @all_request_params ||= http_params.keys.map(&:to_s).sort.uniq
      end
    end
  end
end
