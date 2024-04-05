# frozen_string_literal: true

module Sbmt
  module Strangler
    module Http
      class Client
        include Dry::Monads::Result::Mixin

        def call(url, http_verb, payload: {}, headers: {})
          case http_verb.downcase
          when :get
            transport.get_request(url, params: payload, headers: prepare_headers(headers))
          when :post
            transport.post_request(url, body: payload, headers: prepare_headers(headers))
          else
            raise "unsupported http verb - #{http_verb}"
          end
        end

        private

        def transport
          @transport ||= Sbmt::Strangler::Http::Transport.new
        end

        def prepare_headers(headers)
          headers&.transform_keys { |key| key.sub("HTTP_", "").tr("_", "-") }
        end
      end
    end
  end
end
