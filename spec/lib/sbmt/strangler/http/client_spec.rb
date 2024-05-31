# frozen_string_literal: true

RSpec.describe Sbmt::Strangler::Http::Client do
  describe "#call" do
    subject(:client) { described_class.new }

    let(:transport) { instance_double(Sbmt::Strangler::Http::Transport) }

    before do
      allow(Sbmt::Strangler::Http::Transport).to receive(:new).and_return(transport)
    end

    context "with get request" do
      let(:url) { "http://example.com/get_request" }

      it "does get_request" do
        expect(transport).to receive(:get_request).with(url, params: {}, headers: {})

        client.call(url, :get)
      end

      context "with http headers" do
        let(:headers) { {"HTTP_AUTH_IDENTITY" => "uuid"} }

        it "prepares headers" do
          expect(transport).to receive(:get_request).with(url, params: {}, headers: {"AUTH-IDENTITY" => "uuid"})

          client.call(url, :get, payload: {}, headers: headers)
        end
      end
    end

    context "with post request" do
      let(:url) { "http://example.com/post_request" }

      it "does post_request" do
        expect(transport).to receive(:post_request).with(url, body: {}, headers: {})

        client.call(url, :post, payload: {})
      end

      context "with http headers" do
        let(:headers) { {"HTTP_AUTH_IDENTITY" => "uuid"} }

        it "prepares headers" do
          expect(transport).to receive(:post_request).with(url, body: {}, headers: {"AUTH-IDENTITY" => "uuid"})

          client.call(url, :post, payload: {}, headers: headers)
        end
      end
    end
  end
end
