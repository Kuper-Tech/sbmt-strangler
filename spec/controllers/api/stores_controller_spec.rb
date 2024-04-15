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

      it "renders proxy response", vcr: "api/stores_post_success" do
        get_index
        expect(response.body).to eq('["render_proxy_response"]')
      end

      context "with metrics" do
        let(:params_usage_metric) { Yabeda.sbmt_strangler.params_usage }
        let(:work_mode_metric) { Yabeda.sbmt_strangler.work_mode }
        let(:params) { {} }

        around do |example|
          VCR.use_cassette("api/stores_post_success", match_requests_on: %i[method]) do
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

        it "sends headers to proxied server" do
          request.headers["HTTP_API_VERSION"] = "2.2"
          request.headers["HTTP_USER_AGENT"] = "ios 1.0.0"
          request.headers["HTTP_X_REQUEST_ID"] = "9b8a43fb-ee77-4dc7-b537-821c274951a2"

          get_index

          expect(response).to have_http_status(:success)
        end
      end
    end

    context "with replace mode" do
      include_context "with flipper enabled",
        "Api::StoresController#index - replace_work_mode"

      let(:params) { {} }

      it "returns 200 code" do
        get_index
        expect(response).to have_http_status(:success)
      end

      it "renders from service" do
        get_index
        expect(response.body).to eq('["render_from_service"]')
      end

      context "with metrics" do
        let(:params_usage_metric) { Yabeda.sbmt_strangler.params_usage }
        let(:work_mode_metric) { Yabeda.sbmt_strangler.work_mode }
        let(:params) { {a: 123, lat: 68.4897} }

        after do
          get_index
        end

        it "tracks param usage" do
          expect(params_usage_metric).to receive(:increment).with({params: "lat", controller: "api/stores", action: "index"})
        end

        it "tracks work mode" do
          expect(work_mode_metric).to receive(:increment).with({mode: "replace", params: "lat", controller: "api/stores", action: "index"})
        end
      end
    end

    context "with mirror mode" do
      context "when proxied server responded successfully" do
        around do |example|
          VCR.use_cassette("api/stores_post_success", match_requests_on: %i[method]) do
            example.run
          end
        end

        context "when all extra render/search flags enabled" do
          include_context "with flipper enabled",
            "Api::StoresController#index - mirror_work_mode",
            "Api::StoresController#index - search",
            "Api::StoresController#index - search_compare",
            "Api::StoresController#index - render",
            "Api::StoresController#index - render_compare"

          let(:params) { {} }

          it "returns 200 code" do
            get_index
            expect(response).to have_http_status(:success)
          end

          it "renders proxy response" do
            get_index
            expect(response.body).to eq('["render_proxy_response"]')
          end

          context "with metrics" do
            let(:params_usage_metric) { Yabeda.sbmt_strangler.params_usage }
            let(:work_mode_metric) { Yabeda.sbmt_strangler.work_mode }
            let(:search_accuracy_metric) { Yabeda.sbmt_strangler.search_accuracy }
            let(:render_accuracy_metric) { Yabeda.sbmt_strangler.render_accuracy }
            let(:params) { {a: 123, lat: 68.4897} }

            after do
              get_index
            end

            it "tracks param usage" do
              expect(params_usage_metric).to receive(:increment).with({params: "lat", controller: "api/stores", action: "index"})
            end

            it "tracks work mode" do
              expect(work_mode_metric).to receive(:increment).with({mode: "mirror", params: "lat", controller: "api/stores", action: "index"})
            end

            it "tracks search accuracy" do
              expect(search_accuracy_metric).to receive(:increment).with({match: "true", params: "lat", controller: "api/stores", action: "index"})
            end

            it "tracks render accuracy" do
              expect(render_accuracy_metric).to receive(:increment).with({match: "true", params: "lat", controller: "api/stores", action: "index"})
            end
          end
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
