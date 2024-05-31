# frozen_string_literal: true

describe Sbmt::Strangler::Http do
  describe ".configure_faraday" do
    let(:req_path) { "/get_request" }

    it "applies defaults" do
      conn = Faraday.new { |f| described_class.configure_faraday(f, name: "test-client") }

      expect(conn.options.timeout).to eq(Sbmt::Strangler.configuration.http.timeout)
      expect(conn.options.open_timeout).to eq(Sbmt::Strangler.configuration.http.open_timeout)
      expect(conn.options.read_timeout).to eq(Sbmt::Strangler.configuration.http.read_timeout)
      expect(conn.options.write_timeout).to eq(Sbmt::Strangler.configuration.http.write_timeout)
      expect(conn.builder.adapter).to eq(Faraday::Adapter::NetHttpPersistent)
    end

    it "configures http client" do
      conn = Faraday.new("http://localhost") do |f|
        described_class.configure_faraday(f, name: "test-client")
        f.adapter :test do |stubs|
          stubs.get(req_path) { [200, {}, ""] }
        end
      end

      resp = conn.get("#{req_path}?foo=1")
      expect(resp).to be_success

      expect(Yabeda.sbmt_strangler.http_request_duration.values.keys.last).to eq(name: "test-client",
        method: :get,
        status: 200,
        host: "localhost",
        path: "/get_request")
    end

    it "raises an error if client name is not set" do
      expect do
        Faraday.new("http://localhost") { |f| described_class.configure_faraday(f) }
      end.to raise_error(Sbmt::Strangler::ConfigurationError)
    end

    context "with custom http config" do
      subject(:http_options) do
        controller = Sbmt::Strangler.configuration.controllers.find { _1.name == controller_name }
        controller.actions.find { _1.name == action_name }.http
      end

      context "with global timeout configuration" do
        let(:controller_name) { "api/stores" }
        let(:action_name) { "global_timeout" }

        it "uses global options" do
          expect(http_options.timeout).to eq(10) # global configuration
          expect(http_options.read_timeout).to eq(10) # global configuration
          expect(http_options.write_timeout).to eq(10) # global configuration
          expect(http_options.open_timeout).to eq(Sbmt::Strangler::Http::DEFAULT_HTTP_OPTIONS[:open_timeout])
        end
      end

      context "with controller timeout configuration" do
        let(:controller_name) { "api/timeout" }
        let(:action_name) { "controller_timeout" }

        it "uses controller options" do
          expect(http_options.timeout).to eq(30) # controller configuration
          expect(http_options.read_timeout).to eq(30) # controller configuration
          expect(http_options.write_timeout).to eq(10) # global configuration
          expect(http_options.open_timeout).to eq(Sbmt::Strangler::Http::DEFAULT_HTTP_OPTIONS[:open_timeout])
        end

        context "with action timeout configuration" do
          let(:action_name) { "action_timeout" }

          it "uses action options" do
            expect(http_options.timeout).to eq(60) # action configuration
            expect(http_options.read_timeout).to eq(30) # controller configuration
            expect(http_options.write_timeout).to eq(60) # action configuration
            expect(http_options.open_timeout).to eq(Sbmt::Strangler::Http::DEFAULT_HTTP_OPTIONS[:open_timeout])
          end
        end
      end
    end
  end

  describe "REQUEST_PATH_FILTER_REGEX" do
    [
      SecureRandom.uuid,
      rand(1..1000).to_s,
      "H01234567890-1",
      "H01234567890",
      "R608473650"
    ].each do |id|
      context "when id is #{id.inspect}" do
        it "works as a replacement pattern for id in the middle" do
          path = "/foo/bar/#{id}/baz/42"
          result = path.gsub(described_class::REQUEST_PATH_FILTER_REGEX, "/:id")

          expect(result).to eq("/foo/bar/:id/baz/:id")
        end

        it "works as a replacement pattern for id at the end" do
          path = "/foo/bar/#{id}"
          result = path.gsub(described_class::REQUEST_PATH_FILTER_REGEX, "/:id")

          expect(result).to eq("/foo/bar/:id")
        end
      end
    end
  end
end
