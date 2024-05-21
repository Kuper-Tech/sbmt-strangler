# frozen_string_literal: true

RSpec.describe Sbmt::Strangler::Http::Transport do
  subject(:transport) { described_class.new }

  describe ".persistent" do
    context "with same host" do
      it "use same transport" do
        transport_1 = described_class.persistent("foo.com")
        transport_2 = described_class.persistent("foo.com")

        expect(transport_1).to be(transport_2)
        expect(described_class.instance_variable_get(:@persistent_foo_com)).to be_present

        described_class.instance_variable_set(:@persistent_foo_com, nil)
      end
    end

    context "with different hosts" do
      it "use different transports" do
        transport_1 = described_class.persistent("foo.com")
        transport_2 = described_class.persistent("bar.com")

        expect(transport_1).not_to be(transport_2)
        expect(described_class.instance_variable_get(:@persistent_foo_com)).to be_present
        expect(described_class.instance_variable_get(:@persistent_bar_com)).to be_present

        described_class.instance_variable_set(:@persistent_foo_com, nil)
        described_class.instance_variable_set(:@persistent_bar_com, nil)
      end
    end

    context "without host" do
      it "use different transports" do
        transport_1 = described_class.persistent
        transport_2 = described_class.persistent

        expect(transport_1).not_to be(transport_2)
      end
    end
  end

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
end
