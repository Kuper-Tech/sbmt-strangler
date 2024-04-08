# frozen_string_literal: true

module Orders
end

Sbmt::Strangler.configure do |strangler|
  strangler.controller("api/stores") do |controller|
    controller.headers_allowlist = %w[HTTP_API_VERSION HTTP_USER_AGENT HTTP_X_REQUEST_ID]
    controller.params_tracking_allowlist = %w[lat lon]

    controller.action("index") do |action|
      action.proxy_url = "http://example.com:8080/api/stores"
      action.proxy_http_verb = :post
    end

    controller.action("show") do |action|
      action.proxy_url = lambda { |params, _headers| "http://example.com:8080/api/stores/#{params[:id]}" }
      action.proxy_http_verb = :get
      action.params_tracking_allowlist = %w[id]
    end
  end

  strangler.controller("api/orders/checkout") do |controller|
    controller.action("index") do |action|
      action.proxy_url = "http://example.com:8080/api/stores"
      action.proxy_http_verb = :get
    end
  end
end
