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
          origin_response = proxy_task.value!

          mirror_compare(origin_response, mirror_result)

          render_origin_response(origin_response)
        end

        private

        delegate(
          :http_params, :http_request, :render_origin_response, :track_mirror_compare,
          to: :rails_controller
        )

        class Result < Struct.new(:ok, :value)
          def self.ok(value)
            new(true, value)
          end

          def self.failure
            new(false, nil)
          end
        end

        def mirror
          Result.ok(strangler_action.mirror.call(rails_controller))
        rescue => err
          handle_error(err)
          Result.failure
        end

        MATCH_ERROR = :error

        def mirror_compare(origin_response, mirror_result)
          match =
            if mirror_result&.ok && origin_response.success?
              begin
                cmp = strangler_action.mirror_compare.call(origin_response.value![:body].dup, mirror_result.value)
                raise "starngler_action.compare must return a boolean value!" unless cmp.in?([true, false])
                cmp
              rescue => err
                handle_error(err)
                MATCH_ERROR
              end
            else
              MATCH_ERROR
            end
          track_mirror_compare(match)
        end
      end
    end
  end
end
