# frozen_string_literal: true

require_relative "base"

module Sbmt
  module Strangler
    module WorkModes
      class Replace < Base
        include Dry::Monads::Result::Mixin

        def call
          mirror_call_result = mirror_call
          track_mirror_call(mirror_call_result.success?)

          unless mirror_call_result.success?
            render(
              json: {error: "Mirror lambda call failed!"},
              status: :internal_server_error
            ) # TODO: Возможно стоит сделать фолбэк на проксирование?
            return
          end

          render_call_result = render_call(mirror_call_result.value!)
          track_render_call(render_call_result.success?)

          unless render_call_result.success?
            render(
              json: {error: "Render lambda call failed!"},
              status: :internal_server_error
            ) # TODO: Возможно стоит сделать фолбэк на проксирование?
            return
          end

          render render_call_result.value!
        end

        private

        delegate :render, to: :rails_controller
        delegate :track_mirror_call, :track_render_call, to: :metric_tracker

        def mirror_call
          value = if strangler_action.composition?
            strangler_action.composition.call(rails_controller)
          else
            strangler_action.mirror.call(rails_controller)
          end

          Success(value)
        rescue => err
          handle_error(err)
          Failure(nil)
        end

        def render_call(mirror_result)
          value = strangler_action.render.call(mirror_result)
          Success(value)
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
