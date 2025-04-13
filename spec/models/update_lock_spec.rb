require "rails_helper"

describe UpdateLock, type: :model do
  describe "initializing without a lockable instance" do
    let(:not_lockable) { double(:not_lockable) }

    it "raises an error" do
      expect { described_class.new(not_lockable) }.to raise_error ArgumentError
    end
  end

  describe "#check_availability!" do
    subject { described_class.new(lockable) }

    context "with a nil item" do
      let(:lockable) { nil }

      it "does not raise an error" do
        expect {
          subject.check_availability!(payload_version: "20")
        }.not_to raise_error
      end
    end

    context "with a locked item" do
      let(:lockable) do
        double(
          :lockable,
          payload_version: "20",
        )
      end

      context "without payload_version" do
        let(:attributes) { {} }

        it "raises an error" do
          expect {
            subject.check_availability!(attributes)
          }.to raise_error(
            MissingAttributeError,
          )
        end
      end

      context "with payload_version" do
        context "when existing is higher" do
          let(:payload_version) { "19" }

          it "raises an error" do
            expect {
              subject.check_availability!(payload_version)
            }.to raise_error(
              OutOfOrderTransmissionError,
              /has a newer \(or equal\) payload_version/,
            )
          end
        end

        context "when existing is equal" do
          let(:payload_version) { "20" }

          it "raises an error" do
            expect {
              subject.check_availability!(payload_version)
            }.to raise_error(
              OutOfOrderTransmissionError,
              /has a newer \(or equal\) payload_version/,
            )
          end
        end

        context "when existing is lower" do
          let(:payload_version) { "21" }

          it "does not raise an error" do
            expect {
              subject.check_availability!(payload_version)
            }.not_to raise_error
          end
        end
      end
    end
  end
end
