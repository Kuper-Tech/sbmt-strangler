# frozen_string_literal: true

module Sbmt
  module Strangler
    class ActionInvoker
      module MirrorWorkMode
        private

        class Result < Struct.new(:ok, :value); end

        def mirror_work_mode
          mirror_task = Concurrent::Promises.future { mirror_work_mode_search_and_render }
          proxy_task = Concurrent::Promises.future { http_request(http_params) }

          search_result, render_result = *mirror_task.value!
          proxy_response = proxy_task.value!.freeze

          mirror_work_mode_search_compare(search_result, proxy_response)
          mirror_work_mode_render_compare(render_result, proxy_response)

          render_proxy_response(proxy_response)
        end

        def mirror_work_mode_search_and_render
          search_result = mirror_work_mode_search if enabled?(@action.feature_flags.search)
          render_result = mirror_work_mode_render(search_result.value) if search_result&.ok && enabled?(@action.feature_flags.render)
          [search_result, render_result]
        rescue => err
          handle_mirror_work_mode_error(err)
          [nil, nil]
        end

        def mirror_work_mode_search
          Result.new(true, @action.search.call)
        rescue => err
          handle_mirror_work_mode_error(err)
          Result.new(false, nil)
        end

        def mirror_work_mode_render(search_result_value)
          Result.new(true, @action.render.call(search_result_value))
        rescue => err
          handle_mirror_work_mode_error(err)
          Result.new(false, nil)
        end

        def mirror_work_mode_search_compare(search_result, proxy_response)
          if search_result&.ok && enabled?(@action.feature_flags.search_compare)
            match = @action.search_compare.call(search_result.value, proxy_response.dup)
            raise "@action.search_compare must return a boolean value!" unless match.in?([true, false])
            track_search_accuracy(match)
          end
        rescue => err
          handle_mirror_work_mode_error(err)
        end

        def mirror_work_mode_render_compare(render_result, proxy_response)
          if render_result&.ok && enabled?(@action.feature_flags.render_compare)
            match = @action.render_compare.call(render_result.value, proxy_response.dup)
            raise "@action.search_compare must return a boolean value!" unless match.in?([true, false])
            track_render_accuracy(match)
          end
        rescue => err
          handle_mirror_work_mode_error(err)
        end

        def handle_mirror_work_mode_error(err)
          Sbmt::Strangler.error_tracker.error(err)
          logger.error(err)
        end
      end
    end
  end
end
