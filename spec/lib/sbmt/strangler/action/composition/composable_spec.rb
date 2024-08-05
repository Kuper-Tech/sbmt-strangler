# frozen_string_literal: true

describe Sbmt::Strangler::Action::Composition::Composable do
  let(:composition_klass) do
    Class.new do
      include Sbmt::Strangler::Action::Composition::Composable
    end
  end

  describe ".new" do
    subject(:new) { composition_klass.new(composition_level: composition_level) }

    let(:composition_level) { 0 }

    it "initializes new class" do
      expect(new).to be_present
    end

    context "with composition_level higher than MAX_COMPOSITION_LEVEL" do
      let(:composition_level) { Sbmt::Strangler::Action::Composition::Composable::MAX_COMPOSITION_LEVEL + 1 }

      it "raises MaxCompositionLevelError" do
        expect { new }.to raise_error(Sbmt::Strangler::Action::Composition::Errors::MaxCompositionLevelError)
      end
    end
  end

  describe "#sync" do
    subject(:add_sync_step) { composition_instance.sync(name) }

    let(:composition_instance) do
      composition_klass.new(composition_level: composition_level)
    end

    let(:composition_level) { 0 }
    let(:name) { :service_a }

    it "adds sync step" do
      expect(Sbmt::Strangler::Action::Composition::Step).to receive(:new).with(name: :service_a, composition_level: 1)
      step = add_sync_step
      expect(composition_instance.instance_variable_get(:@sync_steps)[name]).to eq(step)
    end
  end

  describe "#async" do
    subject(:add_async_step) { composition_instance.async(name) }

    let(:composition_instance) do
      composition_klass.new(composition_level: composition_level)
    end

    let(:composition_level) { 0 }
    let(:name) { :service_a }

    it "adds async step" do
      expect(Sbmt::Strangler::Action::Composition::Step).to receive(:new).with(name: :service_a, composition_level: 1)
      step = add_async_step
      expect(composition_instance.instance_variable_get(:@async_steps)[name]).to eq(step)
    end
  end

  describe "#composable?" do
    subject(:composable?) { composition_instance.composable? }

    let(:composition_instance) do
      composition_klass.new
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
end
