# frozen_string_literal: true

require "swagger_helper"

describe Api::StoresController, swagger_doc: "api.yaml" do
  path "/api/stores" do
    get "Получение магазинов" do
      consumes "application/json"
      produces "application/json"

      parameter name: :lat,
        in: :query,
        type: :number,
        required: true

      parameter name: :lon,
        in: :query,
        type: :number,
        required: true

      let(:lon) { 5 }
      let(:lat) { 5 }

      context "with success stf proxy mode", vcr: "api/stores_post_success" do # rubocop:disable RSpec/EmptyExampleGroup
        response "200", "Success" do
          schema({
            type: "array",
            items: {type: "string"}
          })

          run_test!
        end
      end
    end
  end
end
