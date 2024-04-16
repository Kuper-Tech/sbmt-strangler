# frozen_string_literal: true

require_relative "shared_context"

describe Sbmt::Strangler::WorkModes::Proxy do
  describe "#call" do
    include_context "with work mode implemetation context"

    it "renders origin response" do
      params = {a: 123}
      response = "origin_response"
      expect(rails_controller).to receive(:http_params).and_return(params)
      expect(rails_controller).to receive(:http_request).with(params).and_return(response)
      expect(rails_controller).to receive(:render_origin_response).with(response)
      mode.call
    end
  end
end
