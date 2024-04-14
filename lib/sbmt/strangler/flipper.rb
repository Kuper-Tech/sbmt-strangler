# frozen_string_literal: true

module Sbmt
  module Strangler
    module Flipper
      FLIPPER_ID_STRUCT = Struct.new(:flipper_id)
      ONTIME_ACTOR_REGEXP = /^ONTIME:(\d{2})-(\d{2})$/

      class << self
        delegate :add, to: ::Flipper

        def enabled_for_actor?(feature_name, actor)
          return false if feature_name.blank?
          return false if actor.blank?

          ::Flipper.enabled?(feature_name, FLIPPER_ID_STRUCT.new(actor))
        end

        def enabled_on_time?(feature_name)
          return false if feature_name.blank?

          hours_ranges =
            ::Flipper[feature_name]
              .actors_value
              .filter_map { |e|
                e.match(ONTIME_ACTOR_REGEXP) {
                  $LAST_MATCH_INFO.captures.map(&:to_i)
                }
              }
              .compact

          hour_now = DateTime.now.in_time_zone.hour
          hours_ranges.any? { |range| (range.first..range.last).cover?(hour_now) }
        end
      end
    end
  end
end
