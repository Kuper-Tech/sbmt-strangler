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

          Result.new(true, @action.search.call)
        rescue => err
          handle_mirror_work_mode_error(err)
          Result.new(false, :call_error)
        end

        def mirror_work_mode_render(search_result)
          return unless enabled?(@action.feature_flags.render)

          if search_result.nil?
            handle_mirror_work_mode_error("@action.render skipped, because @action.search was not called!")
            return Result.new(false, :nothing_to_render)
          end

          if !search_result.ok
            handle_mirror_work_mode_error("@action.render skipped, because @action.search failed!")
            return Result.new(false, :search_failed)
          end

          Result.new(true, @action.render.call(search_result.value))
        rescue => err
          handle_mirror_work_mode_error(err)
          Result.new(false, :call_error)
        end

        def mirror_work_mode_search_compare(search_result, proxy_response)
          return unless enabled?(@action.feature_flags.search_compare)

          match =
            if search_result&.ok && proxy_response.success?
              begin
                cmp = @action.search_compare.call(search_result.value, proxy_response.value![:body].dup)
                raise "@action.search_compare must return a boolean value!" unless cmp.in?([true, false])
                cmp.to_s
              rescue => err
                handle_mirror_work_mode_error(err)
                "error"
              end
            else
              "error"
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
                cmp.to_s
              rescue => err
                handle_mirror_work_mode_error(err)
                "error"
              end
            else
              "error"
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
