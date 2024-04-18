# frozen_string_literal: true

describe Sbmt::Strangler::Flipper do
  describe ".add" do
    it "is delegated to ::Flipper" do
      expect(::Flipper).to receive(:add).with("feature_name").and_call_original
      described_class.add("feature_name")
    end
  end

  describe ".enabled_for_actor?" do
    subject(:result) { described_class.enabled_for_actor?(feature_name, actor) }

    let(:feature_name) { "feature_name" }
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

      context "when fetaure enabled for another actor" do
        let(:enabled_actor) { "another_actor" }

        it("returns false") { expect(result).to be(false) }
      end
    end

    context "when feature_name is blank" do
      let(:feature_name) { nil }

      it("returns false") { expect(result).to be(false) }
    end

    context "when actor is blank" do
      let(:actor) { nil }

      it("returns false") { expect(result).to be(false) }
    end
  end

  describe ".enabled_on_time?" do # can be flaky but unfortunately
    subject(:result) { described_class.enabled_on_time?(feature_name) }

    let(:feature_name) { "feature_name" }

    it("returns false") { expect(result).to be(false) }

    context "when feature enabled for current hour" do
      let(:enabled_hour) { Time.current.hour }

      before do
        hours_range = "ONTIME:%02d-%02d" % [[enabled_hour - 1, 0].max, [enabled_hour + 1, 23].min]
        ::Flipper.enable(feature_name, Sbmt::Strangler::Flipper::FLIPPER_ID_STRUCT.new(hours_range))
      end

      after do
        ::Flipper.disable(feature_name)
      end

      it("returns true") { expect(result).to be(true) }

      context "when fetaure enabled for another hours range" do
        let(:enabled_hour) { (Time.current.hour > 12) ? 3 : 15 }

        it("returns false") { expect(result).to be(false) }
      end
    end

    context "when feature_name is blank" do
      let(:feature_name) { nil }

      it("returns false") { expect(result).to be(false) }
    end
  end
end
