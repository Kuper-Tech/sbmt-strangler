# frozen_string_literal: true

require "rails/engine"

module Sbmt
  module Strangler
    class Engine < Rails::Engine
      isolate_namespace Sbmt::Strangler
    end
  end
end
