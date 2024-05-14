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

      response "200", "Success" do
        schema({
          type: "array",
          items: {type: "string"}
        })

        context "with success response from the proxied server", vcr: "api/stores_post_success" do
          context "when proxy mode is active by default" do # rubocop:disable RSpec/EmptyExampleGroup
            run_test! do
              expect(response.body).to eq('["origin_result"]')
            end
          end

          context "when mirror mode enabled" do
            include_context "with flipper enabled", "api/stores#index:mirror"

            run_test! do
              expect(response.body).to eq('["origin_result"]')
            end
          end
        end

        context "when replace mode enabled" do
          include_context "with flipper enabled", "api/stores#index:replace"

          run_test! do
            expect(response.body).to eq('["mirror_result"]')
          end
        end
      end
    end
  end
end
