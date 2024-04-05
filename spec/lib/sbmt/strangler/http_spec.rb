# frozen_string_literal: true

describe Sbmt::Strangler::Http do
  describe ".configure_faraday" do
    let(:req_path) { "/get_request" }

    it "applies defaults" do
      conn = Faraday.new { |f| described_class.configure_faraday(f) }

      expect(conn.options.timeout).to eq(described_class::DEFAULT_TIMEOUT)
      expect(conn.options.open_timeout).to eq(described_class::DEFAULT_OPEN_TIMEOUT)
      expect(conn.options.read_timeout).to eq(described_class::DEFAULT_READ_TIMEOUT)
      expect(conn.options.write_timeout).to eq(described_class::DEFAULT_WRITE_TIMEOUT)
      expect(conn.builder.adapter).to eq(Faraday::Adapter::NetHttpPersistent)
    end

    it "configures http client" do
      conn = Faraday.new("http://localhost") do |f|
        described_class.configure_faraday(f)
        f.adapter :test do |stubs|
          stubs.get(req_path) { [200, {}, ""] }
        end
      end

      resp = conn.get("#{req_path}?foo=1")
      expect(resp).to be_success
    end

    context "with custom http config" do
      let(:http_keepalive_pool_size) { 100 }
      let(:http_keepalive_idle_timeout) { 101 }
      let(:http_timeout) { 102 }
      let(:http_read_timeout) { 103 }
      let(:http_write_timeout) { 104 }
      let(:http_open_timeout) { 105 }

      before do
        Sbmt::Strangler.configure do |strangler|
          strangler.http.keepalive_pool_size = http_keepalive_pool_size
          strangler.http.keepalive_idle_timeout = http_keepalive_idle_timeout
          strangler.http.timeout = http_timeout
          strangler.http.read_timeout = http_read_timeout
          strangler.http.write_timeout = http_write_timeout
          strangler.http.open_timeout = http_open_timeout
        end
      end

      after do
        Sbmt::Strangler.configure do |strangler|
          strangler.http.keepalive_pool_size = described_class::DEFAULT_KEEPALIVE_POOL_SIZE
          strangler.http.keepalive_idle_timeout = described_class::DEFAULT_KEEPALIVE_IDLE_TIMEOUT
          strangler.http.timeout = described_class::DEFAULT_TIMEOUT
          strangler.http.read_timeout = described_class::DEFAULT_READ_TIMEOUT
          strangler.http.write_timeout = described_class::DEFAULT_WRITE_TIMEOUT
          strangler.http.open_timeout = described_class::DEFAULT_OPEN_TIMEOUT
        end
      end

      it "overrides defaults" do
        conn = Faraday.new { |f| described_class.configure_faraday(f) }

        expect(conn.options.timeout).to eq(http_timeout)
        expect(conn.options.open_timeout).to eq(http_open_timeout)
      end
    end
  end
end
