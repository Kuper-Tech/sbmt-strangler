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
      REQUEST_PATH_FILTER_REGEX = %r{(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})|(/\d+)|(/[A-Z]\d{11}(-\d{1})?)}

      # Configures Faraday connection. Sets default options and adds default middlewares into chain.
      # Accepts an optional block to configure net-http-persistent-adapter
      #
      # @example
      #
      #   @conn ||= Faraday.new(@base_url) do |f|
      #     Sbmt::Strangler::Http.configure_faraday(f, name: "http-client") do |http|
      #       http.idle_timeout = 42
      #     end
      #     f.timeout = 5
      #     f.response :json
      #   end
      #
      # @param [Faraday::Connection] conn
      # @param [Hash] opts faraday & middlewares options
      # @option opts [String] :name client name for tracing and instrumentation. Required.
      # @option opts [Hash] :adapter_opts net_http_persistent adapter options
      # @option opts [Regexp] :request_path_filter_regex (REQUEST_PATH_FILTER_REGEX) regex for filtering out
      #                       variables from http request metric `path` tag. Set to false to add empty value instead.
      #
      # @return [Faraday::Connection]
      def self.configure_faraday(conn, opts = {})
        raise ConfigurationError, "Faraday client :name must be set" unless opts[:name]

        http_options = Sbmt::Strangler.configuration.http

        conn.options.timeout = http_options.timeout
        conn.options.read_timeout = http_options.read_timeout
        conn.options.open_timeout = http_options.open_timeout
        conn.options.write_timeout = http_options.write_timeout

        configure_faraday_metrics(conn, opts.slice(:name, :request_path_filter_regex))

        adapter_opts = {pool_size: http_options.keepalive_pool_size}.merge(opts[:adapter_opts] || {})
        conn.adapter :net_http_persistent, adapter_opts do |http|
          http.idle_timeout = http_options.keepalive_idle_timeout
          yield http if block_given?
        end

        conn
      end

      def self.configure_faraday_metrics(conn, opts = {})
        @subscribers ||= {}
        name = opts.fetch(:name)
        instrument_full_name = ["request.faraday", name].compact.join(".")
        filter = opts.fetch(:request_path_filter_regex, REQUEST_PATH_FILTER_REGEX)

        conn.request :instrumentation, name: instrument_full_name
        return if @subscribers[instrument_full_name]

        @subscribers[instrument_full_name] = ActiveSupport::Notifications.subscribe(instrument_full_name) do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          env = event.payload

          tags = {
            name: name,
            method: env.method,
            status: env.status || :error,
            host: env.url.host,
            path: filter ? env.url.path.gsub(filter, "/:id") : ""
          }

          Yabeda.sbmt_strangler.http_request_duration.measure(tags, event.duration.fdiv(1000))
        end
      end
    end
  end
end
