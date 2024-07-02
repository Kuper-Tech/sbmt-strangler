# frozen_string_literal: true

RSpec.describe Sbmt::Strangler::Http::Transport do
  subject(:transport) { described_class.new(http_options: Sbmt::Strangler.configuration.http) }

  describe "#get_request" do
    let(:url) { "http://example.com/get_request" }
    let(:response) { {"key" => "value"} }

    around do |example|
      VCR.use_cassette("transport_get_success") do
        example.run
      end
    end

    it "does get_request" do
      result = transport.get_request(url)

      expect(result).to be_success
      expect(result.value![:body]).to eq(response.to_json)
      expect(result.value![:status]).to eq(200)
    end
  end

  describe "#post_request" do
    let(:url) { "http://example.com/post_request" }
    let(:response) { {"key" => "value"} }

    around do |example|
      VCR.use_cassette("transport_post_success") do
        example.run
      end
    end

    it "does post_request" do
      result = transport.post_request(url)

      expect(result).to be_success
      expect(result.value![:body]).to eq(response.to_json)
      expect(result.value![:status]).to eq(200)
    end
  end

  describe "#put_request" do
    let(:url) { "http://example.com/put_request" }
    let(:response) { {"key" => "value"} }

    around do |example|
      VCR.use_cassette("transport_put_success") do
        example.run
      end
    end

    it "does put_request" do
      result = transport.put_request(url)

      expect(result).to be_success
      expect(result.value![:body]).to eq(response.to_json)
      expect(result.value![:status]).to eq(200)
    end
  end

  context "when TimeoutError" do
    let(:connection) { instance_double(Faraday::Connection) }
    let(:error_class) do
      Faraday::TimeoutError
    end
    let(:expected_logger_message) {
      hash_including(
        message: "Sbmt::Strangler::Http::Transport TimeoutError",
        url: url
      )
    }
    let(:url) { "http://example.com/post_request" }

    before do
      allow(Faraday).to receive(:new).and_return(connection)
      allow(connection).to receive(:post).and_raise(error_class)
    end

    it "catches server error and writes it to logger" do
      expect(Rails.logger).to receive(:error).with(expected_logger_message)

      result = transport.post_request(url)

      expect(result).to be_failure
      expect(result.failure[:status]).to eq(:gateway_timeout)
    end
  end

  context "when ConnectionFailed" do
    let(:connection) { instance_double(Faraday::Connection) }
    let(:error_class) do
      Faraday::ConnectionFailed
    end
    let(:url) { "http://example.com/post_request" }

    before do
      allow(Faraday).to receive(:new).and_return(connection)
      allow(connection).to receive(:post).and_raise(error_class)
    end

    it "catches bad_gateway error" do
      expect(connection).to receive(:post).exactly(Sbmt::Strangler::Http::DEFAULT_HTTP_OPTIONS[:retries_count] + 1).times
      result = transport.post_request(url)

      expect(result).to be_failure
      expect(result.failure[:status]).to eq(:bad_gateway)
    end
  end
end
