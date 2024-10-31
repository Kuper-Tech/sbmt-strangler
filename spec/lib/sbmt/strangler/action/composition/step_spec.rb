# frozen_string_literal: true

describe Sbmt::Strangler::Action::Composition::Step do
  describe ".new" do
    subject(:step) do
      described_class.new(
        name: name,
        type: type,
        level: level,
        parent: parent
      )
    end

    let(:name) { :step_name }
    let(:type) { :sync }
    let(:level) { 0 }
    let(:parent) { nil }

    it "sets attributes on the new instance" do
      expect(step)
        .to be_a(described_class)
        .and have_attributes(
          name: name,
          type: type,
          level: level,
          parent: parent
        )
    end

    context "with empty name" do
      let(:name) { "" }

      it "raises ConfigurationError" do
        expect { step }.to raise_error(Sbmt::Strangler::Action::Composition::Errors::ConfigurationError, /name must be a non-empty string or symbol/)
      end
    end

    context "with level higher than MAX_LEVEL" do
      let(:level) { Sbmt::Strangler::Action::Composition::Step::MAX_LEVEL + 1 }

      it "raises MaxLevelError" do
        expect { step }.to raise_error(Sbmt::Strangler::Action::Composition::Errors::MaxLevelError)
      end
    end
  end

  describe "#process" do
    subject(:step) { described_class.new(name: :step_name) }

    it "returns self" do
      ret = step.process { "process_result" }
      expect(ret).to eq(step)
    end
  end

  describe "#compose" do
    subject(:step) { described_class.new(name: :step_name) }

    it "returns self" do
      ret = step.compose { "compose_result" }
      expect(ret).to eq(step)
    end
  end

  describe "#sync" do
    subject(:step) { described_class.new(name: :step_name) }

    it "creates new substep" do
      expect(described_class).to receive(:new).with(
        name: :substep_name,
        type: :sync,
        parent: step,
        level: 1
      ).and_call_original
      step.sync(:substep_name)
    end

    it "returns self" do
      ret = step.sync(:substep_name)
      expect(ret).to eq(step)
    end

    context "when substep is being reopened" do
      let!(:substep) do
        ss = nil
        step.sync(:substep_name) { ss = _1 }
        ss
      end

      it "yields the same substep again" do
        step.sync(:substep_name) do |ss|
          expect(substep).to eq(ss)
        end
      end

      it "raises when trying to change step type" do
        expect { step.async(:substep_name) }.to raise_error(
          Sbmt::Strangler::Action::Composition::Errors::ConfigurationError,
          "Composition step :substep_name has been already defined as sync"
        )
      end
    end
  end

  describe "#async" do
    subject(:step) { described_class.new(name: :step_name) }

    it "creates new substep" do
      expect(described_class).to receive(:new).with(
        name: :substep_name,
        type: :async,
        parent: step,
        level: 1
      ).and_call_original
      step.async(:substep_name)
    end

    it "returns self" do
      ret = step.async(:substep_name)
      expect(ret).to eq(step)
    end

    context "when substep is being reopened" do
      let!(:substep) do
        ss = nil
        step.async(:substep_name) { ss = _1 }
        ss
      end

      it "yields the same substep again" do
        step.async(:substep_name) do |ss|
          expect(substep).to eq(ss)
        end
      end

      it "raises when trying to change step type" do
        expect { step.sync(:substep_name) }.to raise_error(
          Sbmt::Strangler::Action::Composition::Errors::ConfigurationError,
          "Composition step :substep_name has been already defined as async"
        )
      end
    end
  end

  describe "#composite?" do
    subject(:step) { described_class.new(name: :step_name) }

    it "returns false" do
      expect(step.composite?).to be(false)
    end

    context "when substep exists" do
      before { step.sync(:substep_name) }

      it "returns true" do
        expect(step.composite?).to be(true)
      end
    end
  end

  describe "#call" do
    subject(:step) { described_class.new(name: :root_step) }

    let(:rails_controller) do
      instance_double(ActionController::Base, controller_path: "ctrl", action_name: "actn")
    end

    def call
      step.call(rails_controller)
    end

    context "with metrics" do
      before do
        step.process {}.compose {}
        step.sync(:sync_step) { _1.process {} }
        step.async(:async_step) { _1.process {} }
      end

      it "measures root composition step duration" do
        m = Yabeda.sbmt_strangler.composition_step_duration
        t = {step: "root_step", type: "sync", level: "0", parent: nil, controller: "ctrl", action: "actn"}
        expect { call }
          .to measure_yabeda_histogram(m).with_tags(t.merge(part: nil))
          .and measure_yabeda_histogram(m).with_tags(t.merge(part: "process"))
          .and measure_yabeda_histogram(m).with_tags(t.merge(part: "substeps"))
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
        def call
          fail "OpenTelemetry was not expected to be defined" if Object.const_defined?(:OpenTelemetry)

          Object.const_set(:OpenTelemetry, otel)
          step.call(rails_controller)
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
          expect(tracer).to have_received(:in_span).exactly(8)
        end

        it "traces root composition step parts" do
          call
          root_step_in_span_attrs = {
            attributes: {"step" => "root_step", "type" => "sync", "level" => 0},
            kind: :internal
          }
          expect(tracer).to have_received(:in_span).with(
            "Composition step: root_step (sync)",
            root_step_in_span_attrs
          )
          expect(tracer).to have_received(:in_span).with(
            "Composition step: root_step (sync) / process",
            root_step_in_span_attrs.deep_merge(attributes: {"part" => "process"})
          )
          expect(tracer).to have_received(:in_span).with(
            "Composition step: root_step (sync) / substeps",
            root_step_in_span_attrs.deep_merge(attributes: {"part" => "substeps"})
          )
          expect(tracer).to have_received(:in_span).with(
            "Composition step: root_step (sync) / compose",
            root_step_in_span_attrs.deep_merge(attributes: {"part" => "compose"})
          )
        end

        it "traces sync composition step parts" do
          call
          sync_step_in_span_attrs = {
            attributes: {"step" => "sync_step", "type" => "sync", "parent" => "root_step", "level" => 1},
            kind: :internal
          }
          expect(tracer).to have_received(:in_span).with(
            "Composition step: sync_step (sync)",
            sync_step_in_span_attrs
          )
          expect(tracer).to have_received(:in_span).with(
            "Composition step: sync_step (sync) / process",
            sync_step_in_span_attrs.deep_merge(attributes: {"part" => "process"})
          )
        end

        it "traces async composition step parts" do
          call
          async_step_in_span_attrs = {
            attributes: {"step" => "async_step", "type" => "async", "parent" => "root_step", "level" => 1},
            kind: :internal
          }
          expect(tracer).to have_received(:in_span).with(
            "Composition step: async_step (async)",
            async_step_in_span_attrs
          )
          expect(tracer).to have_received(:in_span).with(
            "Composition step: async_step (async) / process",
            async_step_in_span_attrs.deep_merge(attributes: {"part" => "process"})
          )
        end
      end
    end

    context "without substeps" do
      context "when 'process' block is specified" do
        before do
          step.process { |*args| process_algo_double.call(*args) }
        end

        let(:process_algo_double) { instance_double(Proc, call: process_block_result) }
        let(:process_block_result) { instance_double(Hash) }

        it "calls 'process' block with Rails controller instance and Hash of previous steps results" do
          expect(process_algo_double).to receive(:call).with(rails_controller, {}).and_return(process_block_result)
          call
        end

        it "returns 'process' block call result" do
          expect(call).to eq(process_block_result)
        end

        it "doesn't report error" do
          expect(Sbmt::Strangler).not_to receive(:logger).and_call_original
          expect(Sbmt::Strangler).not_to receive(:error_tracker).and_call_original
          call
        end
      end

      context "when 'process' block is not specified" do
        it "returns {}" do
          expect(call).to eq({})
        end

        it "reports error" do
          expect(Sbmt::Strangler).to receive(:logger).and_call_original
          expect(Sbmt::Strangler).to receive(:error_tracker).and_call_original
          call
        end
      end
    end

    context "with substeps" do
      before do
        step.process { "root-step-process-result" }
        step.sync(:sub_step) { |sub_step| sub_step.process { "sub-step-process-result" } }
      end

      context "when 'compose' block is specified" do
        before do
          step.compose { |*args| compose_algo_double.call(*args) }
        end

        let(:compose_algo_double) { instance_double(Proc, call: compose_block_result) }
        let(:compose_block_result) { instance_double(Hash) }

        it "calls 'compose' block with Hash of previous steps results and Rails controller instance" do
          prev_results = {root_step: "root-step-process-result", sub_step: "sub-step-process-result"}
          expect(compose_algo_double).to receive(:call).with(prev_results, rails_controller).and_return(compose_block_result)
          call
        end

        it "returns 'compose' block call result" do
          expect(call).to eq(compose_block_result)
        end

        it "doesn't report error" do
          expect(Sbmt::Strangler).not_to receive(:logger).and_call_original
          expect(Sbmt::Strangler).not_to receive(:error_tracker).and_call_original
          call
        end
      end

      context "when 'compose' block is not specified" do
        it "returns {}" do
          expect(call).to eq({})
        end

        it "reports error" do
          expect(Sbmt::Strangler).to receive(:logger).and_call_original
          expect(Sbmt::Strangler).to receive(:error_tracker).and_call_original
          call
        end
      end
    end

    context "with complex structure" do
      subject!(:step) do
        process = ->(x) {
          ->(*args) {
            call_seq << [x.name, "#process", *args]
            "#{x.name}-process-result"
          }
        }

        compose = ->(x) {
          ->(*args) {
            call_seq << [x.name, "#compose", *args]
            "#{x.name}-compose-result"
          }
        }

        s = described_class.new(name: :root_step)
        s.process(&process.call(s))
        s.compose(&compose.call(s))

        s.sync(:sync_substep_1) do |ss|
          ss.process(&process.call(ss))
          ss.compose(&compose.call(ss))

          ss.sync(:sync_subsubstep_1) do |sss|
            sss.process(&process.call(sss))
          end

          ss.async(:async_subsubstep_1) do |sss|
            sss.process(&process.call(sss))
          end

          ss.sync(:sync_subsubstep_2) do |sss|
            sss.process(&process.call(sss))
          end
        end

        s.async(:async_substep_1) do |ss|
          ss.process(&process.call(ss))
        end

        s
      end

      let!(:call_seq) { [] }

      it "calls all 'process' and 'compose' blocks" do
        call
        expect(call_seq).to contain_exactly(
          [:root_step, "#process", rails_controller, {}],
          [:root_step, "#compose", {
            root_step: "root_step-process-result",
            sync_substep_1: "sync_substep_1-compose-result",
            async_substep_1: "async_substep_1-process-result"
          }, rails_controller],
          [:sync_substep_1, "#process", rails_controller, {
            root_step: "root_step-process-result"
          }],
          [:sync_substep_1, "#compose", {
            root_step: "root_step-process-result",
            sync_substep_1: "sync_substep_1-process-result",
            sync_subsubstep_1: "sync_subsubstep_1-process-result",
            sync_subsubstep_2: "sync_subsubstep_2-process-result",
            async_subsubstep_1: "async_subsubstep_1-process-result"
          }, rails_controller],
          [:async_substep_1, "#process", rails_controller, {
            root_step: "root_step-process-result"
          }],
          [:sync_subsubstep_1, "#process", rails_controller, {
            root_step: "root_step-process-result",
            sync_substep_1: "sync_substep_1-process-result"
          }],
          [:sync_subsubstep_2, "#process", rails_controller, {
            root_step: "root_step-process-result",
            sync_substep_1: "sync_substep_1-process-result",
            sync_subsubstep_1: "sync_subsubstep_1-process-result"
          }],
          [:async_subsubstep_1, "#process", rails_controller, {
            root_step: "root_step-process-result",
            sync_substep_1: "sync_substep_1-process-result"
          }]
        )
      end

      it "returns root step 'compose' block result" do
        expect(call).to eq("root_step-compose-result")
      end
    end
  end
end
