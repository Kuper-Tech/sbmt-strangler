# frozen_string_literal: true

module Sbmt
  module Strangler
    module Metrics
      module Yabeda
        ::Yabeda.configure do
          group :sbmt_strangler do
            counter :params_usage,
              comment: "Parameters usage counter",
              tags: %i[params controller action]
            counter :work_mode,
              comment: "Strangler mode counter: proxy, parallel, render",
              tags: %i[mode params controller action]
          end
        end
      end
    end
  end
end
