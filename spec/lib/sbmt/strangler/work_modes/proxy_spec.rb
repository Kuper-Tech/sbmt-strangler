# frozen_string_literal: true

require_relative "shared_context"

describe Sbmt::Strangler::WorkModes::Proxy do
  describe "#call" do
    include_context "with work mode implementation context"

    it "renders origin response" do
      http_params = {a: 123}
      origin_response = Dry::Monads::Success.new(body: '["origin_result"]', status: 200)
      expect(rails_controller).to receive(:http_params).and_return(http_params)
      expect(rails_controller).to receive(:http_request).with(http_params).and_return(origin_response)
      expect(rails_controller).to receive(:render_origin_response).with(origin_response)
      mode.call
    end
  end
end
