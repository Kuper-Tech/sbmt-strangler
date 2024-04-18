# frozen_string_literal: true

require_relative "base"

module Sbmt
  module Strangler
    module WorkModes
      class Mirror < Base
        def call
          mirror_task = Concurrent::Promises.future { mirror }
          proxy_task = Concurrent::Promises.future { http_request(http_params) }

          mirror_result = mirror_task.value!
          track_mirror_call(mirror_result.ok)

          origin_response = proxy_task.value!

          if mirror_result&.ok && origin_response.success?
            compare_result = compare(origin_response, mirror_result)
            track_compare_call(compare_result.ok)
            track_compare_result(compare_result.value) if compare_result.ok
          end

          render_origin_response(origin_response)
        end

        private

        delegate :http_params, :http_request, :render_origin_response, to: :rails_controller
        delegate :track_mirror_call, :track_compare_call, :track_compare_result, to: :metric_tracker

        class Result < Struct.new(:ok, :value)
          def self.ok(value)
            new(true, value)
          end

          def self.failure
            new(false, nil)
          end
        end

        def mirror
          value = strangler_action.mirror.call(rails_controller)
          Result.ok(value)
        rescue => err
          handle_error(err)
          Result.failure
        end

        MATCH_ERROR = :error

        def compare(origin_response, mirror_result)
          cmp = strangler_action.compare.call(origin_response.value![:body].dup, mirror_result.value)
          raise "Strangler action compare lambda must return a boolean value instead of #{cmp}!" unless cmp.in?([true, false])
          Result.ok(cmp)
        rescue => err
          handle_error(err)
          Result.failure
        end

        def handle_error(err)
          Sbmt::Strangler.error_tracker.error(err)
          Sbmt::Strangler.logger.error(err)
        end
      end
    end
  end
end
