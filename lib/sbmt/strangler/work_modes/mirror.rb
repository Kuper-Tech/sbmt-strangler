# frozen_string_literal: true

require_relative "base"

module Sbmt
  module Strangler
    module WorkModes
      class Mirror < Base
        def call
          mirror_task = Concurrent::Promises.future { search_and_render }
          proxy_task = Concurrent::Promises.future { http_request(http_params) }

          search_result, render_result = *mirror_task.value!
          proxy_response = proxy_task.value!

          search_compare(search_result, proxy_response)
          render_compare(render_result, proxy_response)

          render_proxy_response(proxy_response)
        end

        private

        delegate(
          :http_params, :http_request, :render_proxy_response,
          :track_search_accuracy, :track_render_accuracy,
          to: :@rails_controller
        )

        MATCH_ERROR = :error

        CALL_ERROR = :call_error
        NOTHING_TO_RENDER = :nothing_to_render
        SEARCH_FAILED = :search_failed

        class Result < Struct.new(:ok, :value)
          def self.ok(value)
            new(true, value)
          end

          def self.failure(error)
            new(false, error)
          end
        end

        def search_and_render
          search_result = search
          render_result = render(search_result)
          [search_result, render_result]
        end

        def search
          return unless enabled?(@action.feature_flags.search)

          Result.ok(@action.search.call)
        rescue => err
          handle_error(err)
          Result.failure(CALL_ERROR)
        end

        def render(search_result)
          return unless enabled?(@action.feature_flags.render)

          if search_result.nil?
            handle_error("@action.render skipped, because @action.search was not called!")
            return Result.failure(NOTHING_TO_RENDER)
          end

          if !search_result.ok
            handle_error("@action.render skipped, because @action.search failed!")
            return Result.failure(SEARCH_FAILED)
          end

          Result.ok(@action.render.call(search_result.value))
        rescue => err
          handle_error(err)
          Result.failure(CALL_ERROR)
        end

        def search_compare(search_result, proxy_response)
          return unless enabled?(@action.feature_flags.search_compare)

          match =
            if search_result&.ok && proxy_response.success?
              begin
                cmp = @action.search_compare.call(search_result.value, proxy_response.value![:body].dup)
                raise "@action.search_compare must return a boolean value!" unless cmp.in?([true, false])
                cmp
              rescue => err
                handle_error(err)
                MATCH_ERROR
              end
            else
              MATCH_ERROR
            end
          track_search_accuracy(match)
        end

        def render_compare(render_result, proxy_response)
          return unless enabled?(@action.feature_flags.render_compare)

          match =
            if render_result&.ok && proxy_response.success?
              begin
                cmp = @action.render_compare.call(render_result.value, proxy_response.value![:body].dup)
                raise "@action.render_compare must return a boolean value!" unless cmp.in?([true, false])
                cmp
              rescue => err
                handle_error(err)
                MATCH_ERROR
              end
            else
              MATCH_ERROR
            end
          track_render_accuracy(match)
        end
      end
    end
  end
end
