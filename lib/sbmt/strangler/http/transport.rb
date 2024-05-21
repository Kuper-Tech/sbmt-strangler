# frozen_string_literal: true

module Sbmt
  module Strangler
    module Http
      class Transport
        include Dry::Monads::Do
        include Dry::Monads::Result::Mixin

        class << self
          def persistent(host = nil)
            return new unless host

            name = "@persistent_#{host.gsub(/[.-]/, "_")}"
            instance_variable_get(name) || instance_variable_set(name, new)
          end
        end

        def get_request(url, params: {}, headers: {})
          with_error_handling(url) do
            response = connection.get(url, params, headers)
            Success(body: response.body, status: response.status, headers: response.headers)
          end
        end

        def post_request(url, body: {}, headers: {})
          with_error_handling(url) do
            response = connection.post(url, body, headers)
            Success(body: response.body, status: response.status, headers: response.headers)
          end
        end

        private

        def connection
          @connection ||= Faraday.new do |conn|
            conn.response :raise_error
            Sbmt::Strangler::Http.configure_faraday(conn, name: "strangler_http_client")
            # Skip JSON parsing because
            #   1. it speeds up proxy mode and
            #   2. allows us to duplicate proxy response easily.
            # conn.response :json
            conn.request :json
          end
        end

        def with_error_handling(url)
          yield
        rescue Faraday::UnprocessableEntityError, Faraday::ForbiddenError => error
          Failure(body: error.response_body, status: error.response_status, headers: error.response_headers)
        rescue Faraday::TimeoutError
          Sbmt::Strangler.logger.error(
            message: "Sbmt::Strangler::Http::Transport TimeoutError",
            url: url
          )
          Failure(status: :gateway_timeout)
        rescue Faraday::Error => error
          response = error.response
          Sbmt::Strangler.logger.error(error.message)
          Sbmt::Strangler.error_tracker.error(error)
          return Failure(status: :internal_server_error) unless response

          Failure(body: response[:body], status: response[:status], headers: response[:headers])
        rescue => error
          Sbmt::Strangler.logger.error(error.message)
          Sbmt::Strangler.error_tracker.error(error)
          Failure(status: :internal_server_error)
        end
      end
    end
  end
end
