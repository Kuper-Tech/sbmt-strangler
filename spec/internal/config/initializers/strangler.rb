# frozen_string_literal: true

Sbmt::Strangler.configure do |strangler|
  strangler.http.timeout = 10
  strangler.http.read_timeout = 10
  strangler.http.write_timeout = 10

  strangler.controller("api/stores") do |controller|
    controller.headers_allowlist = %w[HTTP_API_VERSION HTTP_USER_AGENT HTTP_X_REQUEST_ID]
    controller.params_tracking_allowlist = %w[lat lon]

    controller.action("index") do |action|
      action.proxy_url = "http://example.com:8080/api/stores"
      action.proxy_http_method = :post
      action.mirror = ->(_rails_controller) do
        ["mirror_result"]
      end
      action.compare = ->(origin_result, mirror_result) do
        mirror_result == ["mirror_result"] &&
          origin_result[:body] == '["origin_result"]'
      end
      action.render = ->(mirror_result) do
        {json: mirror_result.to_json, status: :ok}
      end
    end

    controller.action("show") do |action|
      action.proxy_url = lambda { |params, _headers| "http://example.com:8080/api/stores/#{params[:id]}" }
      action.params_tracking_allowlist = %w[id]
    end

    controller.action("global_timeout") do |action|
      action.proxy_url = "http://example.com:8080/api/stores"
    end

    controller.action("index_composition_nested") do |action|
      action.proxy_url = "http://example.com:8080/api/stores"
      action.proxy_http_method = :post
      action.compare = ->(origin_result, mirror_result) do
        mirror_result == ["mirror_result"] &&
          origin_result[:body] == '["origin_result"]'
      end
      action.render = ->(mirror_result) do
        {json: mirror_result.to_json, status: :ok}
      end

      action.composition do |root|
        root
          .sync(:service_a) do |service_a|
            service_a
              .process do |rails_controller|
                "service_a_response"
              end
              .async(:service_b) do |service_b|
                service_b.process do |rails_controller, responses|
                  "#{responses[:service_a]}_service_b_response"
                end
              end
              .async(:service_c) do |service_c|
                service_c.process do |rails_controller, responses|
                  "#{responses[:service_a]}_service_c_response"
                end
              end
              .compose do |responses|
                [responses[:service_a], responses[:service_b], responses[:service_c]]
              end
          end
          .compose do |responses|
            responses[:service_a].join(",")
          end
      end
    end

    controller.action("index_composition_async") do |action|
      action.proxy_url = "http://example.com:8080/api/stores"
      action.proxy_http_method = :post
      action.compare = ->(origin_result, mirror_result) do
        mirror_result == ["mirror_result"] &&
          origin_result[:body] == '["origin_result"]'
      end
      action.render = ->(mirror_result) do
        {json: mirror_result.to_json, status: :ok}
      end

      action.composition do |root|
        root
          .async(:service_a) do |service_a|
            service_a.process { |rails_controller| "service_a_response" }
          end
          .async(:service_b) do |service_b|
            service_b.process { |rails_controller| "service_b_response" }
          end
          .compose do |responses|
            [responses[:service_a], responses[:service_b]].join(",")
          end
      end
    end
  end

  strangler.controller("api/orders/checkout") do |controller|
    controller.action("index") do |action|
      action.proxy_url = "http://example.com:8080/api/stores"
    end
  end

  strangler.controller("api/timeout") do |controller|
    controller.http.timeout = 30
    controller.http.read_timeout = 30

    controller.action("action_timeout") do |action|
      action.proxy_url = "http://example.com:8080/api/stores"
      action.http.timeout = 60
      action.http.write_timeout = 60
    end

    controller.action("controller_timeout") do |action|
      action.proxy_url = "http://example.com:8080/api/stores"
    end
  end
end
