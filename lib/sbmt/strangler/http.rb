# frozen_string_literal: true

require_relative "http/client"
require_relative "http/transport"

module Sbmt
  module Strangler
    module Http
      DEFAULT_KEEPALIVE_POOL_SIZE = 20
      DEFAULT_KEEPALIVE_IDLE_TIMEOUT = 90
      DEFAULT_TIMEOUT = 30
      DEFAULT_READ_TIMEOUT = 30
      DEFAULT_WRITE_TIMEOUT = 30
      DEFAULT_OPEN_TIMEOUT = 10

      # Configures Faraday connection. Sets default options and adds default middlewares into chain.
      # Accepts an optional block to configure net-http-persistent-adapter
      #
      # @example
      #
      #   @conn ||= Faraday.new(@base_url) do |f|
      #     Sbmt::Strangler::Http.configure_faraday(f) do |http|
      #       http.idle_timeout = 42
      #     end
      #     f.timeout = 5
      #     f.response :json
      #   end
      #
      # @param [Faraday::Connection] conn
      # @param [Hash] opts faraday & middlewares options
      # @option opts [Hash] :adapter_opts net_http_persistent adapter options
      #
      # @return [Faraday::Connection]
      def self.configure_faraday(conn, opts = {})
        http_options = Sbmt::Strangler.configuration.http

        conn.options.timeout = http_options.timeout
        conn.options.read_timeout = http_options.read_timeout
        conn.options.open_timeout = http_options.open_timeout
        conn.options.write_timeout = http_options.write_timeout

        adapter_opts = {pool_size: http_options.keepalive_pool_size}.merge(opts[:adapter_opts] || {})
        conn.adapter :net_http_persistent, adapter_opts do |http|
          http.idle_timeout = http_options.keepalive_idle_timeout
          yield http if block_given?
        end

        conn
      end
    end
  end
end
