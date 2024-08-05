# frozen_string_literal: true

Rails.application.routes.draw do
  get "api/stores", to: "api/stores#index"
  get "api/stores/:id", to: "api/stores#show"
  get "api/stores/index_composition_nested", to: "api/stores#index_composition_nested"
  get "api/stores/index_composition_async", to: "api/stores#index_composition_async"
end
