# frozen_string_literal: true

require_relative "base"

module Sbmt
  module Strangler
    module WorkModes
      class Mirror < Base
        include Dry::Monads::Result::Mixin

        def call
          mirror_task = Concurrent::Promises.future { mirror_call }
          proxy_task = Concurrent::Promises.future { http_request(http_params) }

          mirror_call_result = mirror_task.value!
          origin_response = proxy_task.value!

          begin
            track_mirror_call(mirror_call_result.success?)
            if mirror_call_result.success?
              mirror_result = mirror_call_result.value!
              origin_result = copy_of_origin_result(origin_response)
              compare_call_result = compare_call(origin_result, mirror_result)
              track_compare_call(compare_call_result.success?)
              track_compare_call_result(compare_call_result.value!) if compare_call_result.success?
            end
          rescue => err
            handle_error(err)
          end

          render_origin_response(origin_response)
        end

        private

        delegate :http_params, :http_request, :render_origin_response, to: :rails_controller
        delegate :track_mirror_call, :track_compare_call, :track_compare_call_result, to: :metric_tracker

        def copy_of_origin_result(origin_response)
          if origin_response.success?
            origin_response.value!.deep_dup
          else
            origin_response.failure.deep_dup
          end
        end

        def mirror_call
          value = strangler_action.mirror.call(rails_controller)
          Success(value)
        rescue => err
          handle_error(err)
          Failure(nil)
        end

        MATCH_ERROR = :error

        def compare_call(origin_result, mirror_result)
          cmp = strangler_action.compare.call(origin_result, mirror_result)
          raise "Strangler action compare lambda must return a boolean value instead of #{cmp}!" unless cmp.in?([true, false])
          Success(cmp)
        rescue => err
          handle_error(err)
          Failure(nil)
        end

        def handle_error(err)
          Sbmt::Strangler.error_tracker.error(err)
          Sbmt::Strangler.logger.error(err)
        end
      end
    end
  end
end
