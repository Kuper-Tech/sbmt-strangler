# frozen_string_literal: true

# rubocop:disable RSpec/RemoveConst
describe Sbmt::Strangler::ConstDefiner do
  describe ".call!" do
    subject(:define_const) { described_class.call!(const_name, klass) }

    let(:klass) do
      Class.new do
        def self.ping
          "pong"
        end
      end
    end

    context "with modules" do
      let(:const_name) { "Module1::Module2::MyTestController" }

      it "defines controller const" do
        expect(Object).not_to have_constant(const_name)
        define_const
        expect(Object).to have_constant(const_name)
        expect(const_name.constantize.ping).to eq("pong")

        Module1::Module2.send(:remove_const, "MyTestController")
        Module1.send(:remove_const, "Module2")
        Object.send(:remove_const, "Module1")
      end

      context "with existed module" do
        before do
          stub_const("Module1::Module2", Module.new)
        end

        it "defines controller const" do
          expect(Object).to have_constant("Module1::Module2")
          expect(Object).not_to have_constant(const_name)
          define_const
          expect(Object).to have_constant(const_name)
          expect(const_name.constantize.ping).to eq("pong")

          Module1::Module2.send(:remove_const, "MyTestController")
        end
      end
    end

    context "without modules single class" do
      let(:const_name) { "MyTestController" }

      it "defines controller const" do
        expect(Object).not_to have_constant(const_name)
        define_const
        expect(Object).to have_constant(const_name)
        expect(const_name.constantize.ping).to eq("pong")

        Object.send(:remove_const, "MyTestController")
      end

      context "with existed class" do
        before do
          stub_const(const_name, Class.new)
        end

        it "defines controller const" do
          expect(Object).to have_constant(const_name)
          define_const
          expect(Object).to have_constant(const_name)
          expect(const_name.constantize.ping).to eq("pong")
        end
      end
    end
  end
end
# rubocop:enable RSpec/RemoveConst
