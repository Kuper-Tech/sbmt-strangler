# frozen_string_literal: true

describe Sbmt::Strangler::Action::Composition::Step do
  describe ".new" do
    subject(:new) { described_class.new(name: :step_name, level: level) }

    let(:level) { 0 }

    it "initializes new class" do
      expect(new).to be_present
    end

    context "with level higher than MAX_LEVEL" do
      let(:level) { Sbmt::Strangler::Action::Composition::Step::MAX_LEVEL + 1 }

      it "raises MaxLevelError" do
        expect { new }.to raise_error(Sbmt::Strangler::Action::Composition::Errors::MaxLevelError)
      end
    end
  end

  describe "#sync" do
    subject(:add_sync_step) { composition_instance.sync(name) }

    let!(:composition_instance) do
      described_class.new(name: :step_name, level: level)
    end

    let(:level) { 0 }
    let(:name) { :service_a }

    it "adds sync step" do
      expect(described_class).to receive(:new).with(name: :service_a, type: :sync, parent: composition_instance, level: 1)
      step = add_sync_step
      expect(composition_instance.instance_variable_get(:@sync_steps)[name]).to eq(step)
    end
  end

  describe "#async" do
    subject(:add_async_step) { composition_instance.async(name) }

    let!(:composition_instance) do
      described_class.new(name: :step_name, level: level)
    end

    let(:level) { 0 }
    let(:name) { :service_a }

    it "adds async step" do
      expect(described_class).to receive(:new).with(name: :service_a, type: :async, parent: composition_instance, level: 1)
      step = add_async_step
      expect(composition_instance.instance_variable_get(:@async_steps)[name]).to eq(step)
    end
  end

  describe "#composable?" do
    subject(:composable?) { composition_instance.send(:composable?) }

    let!(:composition_instance) do
      described_class.new(name: :step_name)
    end

    it "return false" do
      expect(composable?).to be_falsey
    end

    context "with included step" do
      it "return false" do
        composition_instance.sync(:service_a)

        expect(composable?).to be_truthy
      end
    end
  end

  describe "#call" do
    subject(:composition_step) do
      step = described_class.new(name: :root_step)
      step.sync(:sync_step).process {}
      step.async(:async_step).process {}
      step.process {}.compose {}
    end

    let(:rails_controller) do
      instance_double(ActionController::Base, controller_path: "ctrl", action_name: "actn")
    end

    let(:call) { composition_step.call(rails_controller) }

    it "measures root composition step duration" do
      m = Yabeda.sbmt_strangler.composition_step_duration
      t = {step: "root_step", type: "sync", level: "0", parent: nil, controller: "ctrl", action: "actn"}
      expect { call }
        .to measure_yabeda_histogram(m).with_tags(t.merge(part: nil))
        .and measure_yabeda_histogram(m).with_tags(t.merge(part: "process"))
        .and measure_yabeda_histogram(m).with_tags(t.merge(part: "compose"))
    end

    it "measures sync composition step duration" do
      m = Yabeda.sbmt_strangler.composition_step_duration
      t = {step: "sync_step", type: "sync", level: "1", parent: "root_step", controller: "ctrl", action: "actn"}
      expect { call }
        .to measure_yabeda_histogram(m).with_tags(t.merge(part: "process"))
        .and measure_yabeda_histogram(m).with_tags(t.merge(part: nil))
    end

    it "measures async composition step duration" do
      m = Yabeda.sbmt_strangler.composition_step_duration
      t = {step: "async_step", type: "async", level: "1", parent: "root_step", controller: "ctrl", action: "actn"}
      expect { call }
        .to measure_yabeda_histogram(m).with_tags(t.merge(part: "process"))
        .and measure_yabeda_histogram(m).with_tags(t.merge(part: nil))
    end

    context "when OpenTelemetry defined" do
      let(:call) do
        fail "OpenTelemetry was not expected to be defined by this test" if Object.const_defined?(:OpenTelemetry)

        Object.const_set(:OpenTelemetry, otel)
        composition_step.call(rails_controller)
        Object.send(:remove_const, :OpenTelemetry) # rubocop:disable RSpec/RemoveConst
      end

      # rubocop:disable RSpec/VerifiedDoubles
      # FIXME: Rewrite test using verified doubles?
      let(:otel) { double(:otel, tracer_provider: tracer_provider) }
      let(:tracer_provider) { double(:tracer_provider, tracer: tracer) }
      let(:tracer) { double(:tracer) }
      # rubocop:enable RSpec/VerifiedDoubles

      before do
        allow(tracer).to receive(:in_span).and_yield(nil)
      end

      it "traces all composition steps" do
        call

        expect(tracer).to have_received(:in_span).exactly(7)

        expect(tracer).to have_received(:in_span)
          .with("Composition step: root_step", attributes: {type: "sync", level: 0}, kind: :internal)
        expect(tracer).to have_received(:in_span)
          .with("Composition step: root_step (process)", attributes: {type: "sync", level: 0}, kind: :internal)
        expect(tracer).to have_received(:in_span)
          .with("Composition step: root_step (compose)", attributes: {type: "sync", level: 0}, kind: :internal)

        expect(tracer).to have_received(:in_span)
          .with("Composition step: sync_step", attributes: {type: "sync", parent: "root_step", level: 1}, kind: :internal)
        expect(tracer).to have_received(:in_span)
          .with("Composition step: sync_step (process)", attributes: {type: "sync", parent: "root_step", level: 1}, kind: :internal)

        expect(tracer).to have_received(:in_span)
          .with("Composition step: async_step", attributes: {type: "async", parent: "root_step", level: 1}, kind: :internal)
        expect(tracer).to have_received(:in_span)
          .with("Composition step: async_step (process)", attributes: {type: "async", parent: "root_step", level: 1}, kind: :internal)
      end
    end
  end
end
