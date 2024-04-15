# frozen_string_literal: true

module Sbmt
  module Strangler
    class ActionInvoker
      module WorkModes
        module Mirror
          private

          COMPARE_MATCH_ERROR = :error

          class LambdaCallResult < Struct.new(:ok, :value)
            CALL_ERROR = :call_error
            NOTHING_TO_RENDER = :nothing_to_render
            SEARCH_FAILED = :search_failed

            def self.ok(value)
              new(true, value)
            end

            def self.failure(error)
              new(false, error)
            end
          end

          def mirror_work_mode
            mirror_task = Concurrent::Promises.future { mirror_work_mode_search_and_render }
            proxy_task = Concurrent::Promises.future { http_request(http_params) }

            search_result, render_result = *mirror_task.value!
            proxy_response = proxy_task.value!

            mirror_work_mode_search_compare(search_result, proxy_response)
            mirror_work_mode_render_compare(render_result, proxy_response)

            render_proxy_response(proxy_response)
          end

          def mirror_work_mode_search_and_render
            search_result = mirror_work_mode_search
            render_result = mirror_work_mode_render(search_result)
            [search_result, render_result]
          end

          def mirror_work_mode_search
            return unless enabled?(@action.feature_flags.search)

            LambdaCallResult.ok(@action.search.call)
          rescue => err
            handle_mirror_work_mode_error(err)
            LambdaCallResult.failure(LambdaCallResult::CALL_ERROR)
          end

          def mirror_work_mode_render(search_result)
            return unless enabled?(@action.feature_flags.render)

            if search_result.nil?
              handle_mirror_work_mode_error("@action.render skipped, because @action.search was not called!")
              return LambdaCallResult.failure(LambdaCallResult::NOTHING_TO_RENDER)
            end

            if !search_result.ok
              handle_mirror_work_mode_error("@action.render skipped, because @action.search failed!")
              return LambdaCallResult.failure(LambdaCallResult::SEARCH_FAILED)
            end

            LambdaCallResult.ok(@action.render.call(search_result.value))
          rescue => err
            handle_mirror_work_mode_error(err)
            LambdaCallResult.failure(LambdaCallResult::CALL_ERROR)
          end

          def mirror_work_mode_search_compare(search_result, proxy_response)
            return unless enabled?(@action.feature_flags.search_compare)

            match =
              if search_result&.ok && proxy_response.success?
                begin
                  cmp = @action.search_compare.call(search_result.value, proxy_response.value![:body].dup)
                  raise "@action.search_compare must return a boolean value!" unless cmp.in?([true, false])
                  cmp
                rescue => err
                  handle_mirror_work_mode_error(err)
                  COMPARE_MATCH_ERROR
                end
              else
                COMPARE_MATCH_ERROR
              end
            track_search_accuracy(match)
          end

          def mirror_work_mode_render_compare(render_result, proxy_response)
            return unless enabled?(@action.feature_flags.render_compare)

            match =
              if render_result&.ok && proxy_response.success?
                begin
                  cmp = @action.render_compare.call(render_result.value, proxy_response.value![:body].dup)
                  raise "@action.render_compare must return a boolean value!" unless cmp.in?([true, false])
                  cmp
                rescue => err
                  handle_mirror_work_mode_error(err)
                  COMPARE_MATCH_ERROR
                end
              else
                COMPARE_MATCH_ERROR
              end
            track_render_accuracy(match)
          end

          def handle_mirror_work_mode_error(err)
            Sbmt::Strangler.error_tracker.error(err)
            logger.error(err)
          end
        end
      end
    end
  end
end
