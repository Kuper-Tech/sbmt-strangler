# frozen_string_literal: true

describe Api::StoresController do
  describe "GET index" do
    subject(:get_index) { get(:index, params: params) }

    context "with proxy mode" do
      let(:params) {
        {
          lat: 5,
          lon: 5
        }
      }

      it "returns 200 code", vcr: "api/stores_post_success" do
        get_index
        expect(response).to have_http_status(:success)
      end

      context "with metrics" do
        let(:params_usage_metric) { Yabeda.sbmt_strangler.params_usage }
        let(:work_mode_metric) { Yabeda.sbmt_strangler.work_mode }
        let(:params) { {} }

        around do |example|
          VCR.use_cassette("api/stores_post_success", match_requests_on: %i[method], tag: :stf) do
            example.run
          end
        end

        after do
          get_index
        end

        context "with empty params" do
          it "track usage_params" do
            expect(params_usage_metric).to receive(:increment).with({params: "", controller: "api/stores", action: "index"})
          end

          it "tracks work mode" do
            expect(work_mode_metric).to receive(:increment).with({mode: "proxy", params: "", controller: "api/stores", action: "index"})
          end
        end

        context "with params" do
          let(:params) do
            {
              lat: 5,
              lon: 5
            }
          end

          it "track usage_params" do
            expect(params_usage_metric).to receive(:increment).with({params: "lat,lon", controller: "api/stores", action: "index"})
          end

          it "tracks work mode" do
            expect(work_mode_metric).to receive(:increment).with({mode: "proxy", params: "lat,lon", controller: "api/stores", action: "index"})
          end
        end

        context "with additional params" do
          let(:params) do
            {
              lat: 5,
              lon: 5,
              page: 1
            }
          end

          it "track usage_params" do
            expect(params_usage_metric).to receive(:increment).with({params: "lat,lon", controller: "api/stores", action: "index"})
          end

          it "tracks work mode" do
            expect(work_mode_metric).to receive(:increment).with({mode: "proxy", params: "lat,lon", controller: "api/stores", action: "index"})
          end
        end

        context "with additional params only" do
          let(:params) do
            {
              per_page: 1,
              page: 1
            }
          end

          it "track usage_params" do
            expect(params_usage_metric).to receive(:increment).with({params: "", controller: "api/stores", action: "index"})
          end

          it "tracks work mode" do
            expect(work_mode_metric).to receive(:increment).with({mode: "proxy", params: "", controller: "api/stores", action: "index"})
          end
        end
      end

      context "with proxied headers" do
        around do |example|
          VCR.use_cassette("api/stores_success_headers", match_requests_on: %i[uri method headers]) do
            example.run
          end
        end

        let(:params) do
          {
            lat: 5,
            lon: 5
          }
        end

        it "sends headers to stf" do
          request.headers["HTTP_API_VERSION"] = "2.2"
          request.headers["HTTP_USER_AGENT"] = "ios 1.0.0"
          request.headers["HTTP_X_REQUEST_ID"] = "9b8a43fb-ee77-4dc7-b537-821c274951a2"

          get_index

          expect(response).to have_http_status(:success)
        end
      end
    end
  end

  describe "GET show" do
    subject(:get_show) { get(:show, params: params) }

    context "with proxy mode" do
      let(:params) {
        {
          id: 1
        }
      }

      it "returns 200 code", vcr: "api/store_get_success" do
        get_show
        expect(response).to have_http_status(:success)
      end
    end
  end
end
