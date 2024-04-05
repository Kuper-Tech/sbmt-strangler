# frozen_string_literal: true

def without_prometheus_adapter
  prometheus = Yabeda.adapters.delete(:prometheus)
  yield
  Yabeda.adapters[:prometheus] = prometheus
end
