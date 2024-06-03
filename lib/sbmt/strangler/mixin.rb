# frozen_string_literal: true

module Sbmt
  module Strangler
    module Mixin
      attr_reader :strangler_action

      def http_params
        params.to_unsafe_h.except(:action, :controller, :format)
      end

      def allowed_params
        return http_params if strangler_action.params_tracking_allowlist.blank?

        params.permit(*strangler_action.params_tracking_allowlist).to_h
      end

      def allowed_headers
        if strangler_action.headers_allowlist.blank?
          return request.headers.select { |name, _| name.starts_with?("HTTP_") }.to_h
        end

        request.headers.select { |name, _| name.in?(strangler_action.headers_allowlist) }.to_h
      end

      def http_request(payload)
        strangler_action.http_client.call(
          proxy_url,
          strangler_action.proxy_http_method,
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

      def render_origin_response(response)
        if response.success?
          body, status = response.value!.values_at(:body, :status)
          render json: body, status: status
          return
        end

        body, status = response.failure.values_at(:body, :status)
        render json: body, status: status
      end
    end
  end
end
