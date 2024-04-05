# frozen_string_literal: true

describe Sbmt::Strangler::ErrorTracker do
  let(:error) { StandardError.new("wrong attr") }
  let(:message) { "Add new error" }
  let(:params) { {response: "qwerty"} }

  describe ".error" do
    it "is exception without parameters" do
      expect(Sentry).to receive(:capture_exception).with(error, level: :error)
      described_class.error(error)
    end

    it "is exception with parameters" do
      expect(Sentry).to receive(:capture_exception).with(error, level: :error)
      described_class.error(error, params)
    end

    it "is message" do
      expect(Sentry).to receive(:capture_message).with(message, level: :error)
      described_class.error(message)
    end
  end
end
