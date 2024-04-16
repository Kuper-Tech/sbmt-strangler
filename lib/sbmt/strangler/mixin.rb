# frozen_string_literal: true

module Sbmt
  module Strangler
    module Mixin
      delegate :logger, to: "Sbmt::Strangler"

      attr_reader :strangler_action

      def http_params
        params.to_unsafe_h.except(:action, :controller, :format)
      end

      def allowed_params
        return http_params if strangler_action.params_tracking_allowlist.blank?

        params.permit(*strangler_action.params_tracking_allowlist)
      end

      def allowed_headers
        if strangler_action.headers_allowlist.blank?
          return request.headers.select { |name, _| name.starts_with?("HTTP_") }.to_h
        end

        request.headers.select { |name, _| name.in?(strangler_action.headers_allowlist) }.to_h
      end

      def http_request(payload)
        http_client.call(
          proxy_url,
          strangler_action.proxy_http_verb,
          payload: payload,
          headers: allowed_headers
        )
      end

      def proxy_url
        case strangler_action.proxy_url
        in String => url
          url
        in Proc => proc
          proc.call(http_params, request.headers)
        end
      end

      def http_client
        @http_client ||= Sbmt::Strangler::Http::Client.new
      end

      def render_origin_response(response)
        if response.success?
          body, status = response.value!.values_at(:body, :status)
          render json: body, status: status
          return
        end

        body, status = response.failure.values_at(:body, :status)
        render json: body, status: status
      end

      def track_params_usage(
        all_request_params: http_params.keys.map(&:to_s),
        allowed_request_params: allowed_params.keys.map(&:to_s)
      )
        yabeda_tags = {
          params: (all_request_params & allowed_request_params).sort.join(","),
          controller: controller_path,
          action: action_name
        }
        Yabeda.sbmt_strangler.params_usage.increment(yabeda_tags)

        unexpected_params = all_request_params - allowed_request_params
        if unexpected_params.any?
          logger.log_info("#{self.class.name}##{action_name} method was called with unexpected parameters: #{unexpected_params}")
        end
      end

      def track_work_mode(mode, params = allowed_params)
        yabeda_tags = {
          mode: mode.to_s,
          params: params.to_h&.keys&.sort&.join(","),
          controller: controller_path,
          action: action_name
        }
        Yabeda.sbmt_strangler.work_mode.increment(yabeda_tags)
      end

      def track_mirror_compare(match, params = allowed_params)
        yabeda_tags = {
          match: match.to_s,
          params: params.to_h&.keys&.sort&.join(","),
          controller: controller_path,
          action: action_name
        }
        Yabeda.sbmt_strangler.mirror_compare.increment(yabeda_tags)
      end
    end
  end
end
