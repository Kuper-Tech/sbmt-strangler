# frozen_string_literal: true

describe Sbmt::Strangler::Flipper do
  include ActiveSupport::Testing::TimeHelpers

  describe ".add" do
    it "is delegated to ::Flipper" do
      expect(::Flipper).to receive(:add).with("feature_name").and_call_original
      described_class.add("feature_name")
    end
  end

  describe ".enabled?" do
    let(:feature_name) { "feature_name" }

    context "when checking without actor" do
      subject(:result) { described_class.enabled?(feature_name) }

      it("returns false") { expect(result).to be(false) }

      context "when feature enabled" do
        before { ::Flipper.enable(feature_name) }
        after { ::Flipper.disable(feature_name) }

        it("returns true") { expect(result).to be(true) }
      end

      context "when feature_name is blank" do
        let(:feature_name) { "" }

        it("raises error") { expect { result }.to raise_error(/feature name is blank/) }
      end
    end

    context "when checking for an actor" do
      subject(:result) { described_class.enabled?(feature_name, actor) }

      let(:actor) { "actor" }

      it("returns false") { expect(result).to be(false) }

      context "when feature enabled for actor" do
        let(:enabled_actor) { actor }

        before do
          ::Flipper.enable(feature_name, Sbmt::Strangler::Flipper::FLIPPER_ID_STRUCT.new(enabled_actor))
        end

        after do
          ::Flipper.disable(feature_name)
        end

        it("returns true") { expect(result).to be(true) }

        context "when feature enabled for another actor" do
          let(:enabled_actor) { "another_actor" }

          it("returns false") { expect(result).to be(false) }
        end

        context "when checking for multiple actors" do
          subject(:result) do
            described_class.enabled?(feature_name, actor, another_actor)
          end

          let(:another_actor) { "another_actor" }

          it("returns true") { expect(result).to be(true) }

          context "when feature enabled for another actor" do
            let(:enabled_actor) { another_actor }

            it("returns true") { expect(result).to be(true) }
          end

          context "when feature enabled for third actor" do
            let(:enabled_actor) { "third_actor" }

            it("returns false") { expect(result).to be(false) }
          end
        end
      end

      context "when feature_name is blank" do
        let(:feature_name) { "" }

        it("raises error") { expect { result }.to raise_error(/feature name is blank/) }
      end
    end
  end

  # **Warning!** This test depends on `Time.current` so it can be flaky.
  describe ".enabled_on_time?" do
    subject(:result) { described_class.enabled_on_time?(feature_name) }

    let(:feature_name) { "feature_name" }

    context "when feature enabled for current hour" do
      around { |ex| travel_to(time_to_travel_to, &ex) }

      before do
        hours_range = "ONTIME:#{start_hour}-#{end_hour}"
        ::Flipper.enable(feature_name, Sbmt::Strangler::Flipper::FLIPPER_ID_STRUCT.new(hours_range))
      end

      after { ::Flipper.disable(feature_name) }

      let(:start_hour) { "18" }
      let(:end_hour) { "23" }

      let(:now) { DateTime.now.in_time_zone }
      let(:time_to_travel_to) { now }

      context "when feature enabled for another hours range" do
        let(:time_to_travel_to) { now.change(hour: 7) }

        it("returns false") { expect(result).to be(false) }
      end

      context "when feature enabled for correct hours range" do
        let(:time_to_travel_to) { now.change(hour: 20) }

        it("returns true") { expect(result).to be(true) }
      end

      context "when feature enabled for end_hour" do
        let(:time_to_travel_to) { now.change(hour: 23, minutes: 10) }

        it("returns false") { expect(result).to be(false) }
      end

      context "when feature enabled for start_hour" do
        let(:time_to_travel_to) { now.change(hour: 18, minutes: 10) }

        it("returns true") { expect(result).to be(true) }
      end

      context "when start_hour eq end_hour" do
        let(:start_hour) { "02" }
        let(:end_hour) { "02" }
        let(:time_to_travel_to) { now.change(hour: 12) }

        it("returns true") { expect(result).to be(true) }
      end

      context "when feature enabled and goes through for 00 hours range?" do
        let(:start_hour) { "18" }
        let(:end_hour) { "05" }

        context "when result is false" do
          context "when time before start_hour" do
            let(:time_to_travel_to) { now.change(hour: 16) }

            it("returns false") { expect(result).to be(false) }
          end

          context "when time after end_hour" do
            let(:time_to_travel_to) { now.change(hour: 7) }

            it("returns false") { expect(result).to be(false) }
          end

          context "when start and end hours close" do
            let(:start_hour) { "03" }
            let(:end_hour) { "02" }
            let(:time_to_travel_to) { now.change(hour: 2, minutes: 10) }

            it("returns false") { expect(result).to be(false) }
          end
        end

        context "when result is true" do
          let(:time_to_travel_to) { now.change(hour: 20) }

          it("returns true") { expect(result).to be(true) }

          context "when start and end hours close" do
            let(:start_hour) { "03" }
            let(:end_hour) { "02" }
            let(:time_to_travel_to) { now.change(hour: 3, minutes: 10) }

            it("returns true") { expect(result).to be(true) }
          end
        end
      end
    end

    context "when feature_name is blank" do
      let(:feature_name) { "" }

      it("raises error") { expect { result }.to raise_error(/feature name is blank/) }
    end
  end
end
