# frozen_string_literal: true

require_relative "composition/errors/max_composition_level_error"
require_relative "composition/composable"
require_relative "composition/step"

module Sbmt
  module Strangler
    class Action
      class Composition
        include Composable
      end
    end
  end
end
