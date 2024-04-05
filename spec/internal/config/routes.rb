# frozen_string_literal: true

Rails.application.routes.draw do
  get "api/stores", to: "api/stores#index"
  get "api/stores/:id", to: "api/stores#show"
end
