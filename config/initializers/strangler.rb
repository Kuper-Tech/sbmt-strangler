# frozen_string_literal: true

Rails.application.config.after_initialize do
  Sbmt::Strangler::Builder.call!
end
