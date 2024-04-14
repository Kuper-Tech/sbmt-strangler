# frozen_string_literal: true

shared_context "with flipper enabled" do |*features|
  before do
    features.each { |feature_name| Flipper.enable(feature_name) }
  end

  after do
    features.each { |feature_name| Flipper.disable(feature_name) }
  end
end
