require "rails_helper"

describe ContentItem, type: :model do
  describe ".create_or_replace" do
    before do
      @item = build(:content_item)
      allow_any_instance_of(UpdateLock)
        .to receive(:check_availability!)
    end

    it "sets updated_at and created_at timestamps" do
      _, item = described_class.create_or_replace(@item.base_path, { schema_name: "publication" })
      expect(item.created_at).to be_kind_of(ActiveSupport::TimeWithZone)
      expect(item.updated_at).to be_kind_of(ActiveSupport::TimeWithZone)
    end

    it "maintains the created_at value from previous item" do
      @item.save!
      _, item = described_class.create_or_replace(@item.base_path, { schema_name: "publication" })
      expect(item.reload.created_at).to eq(@item.reload.created_at)
    end

    context "when there is already an existing item with the same base_path" do
      before do
        @item.update!(
          base_path: @item.base_path,
          title: "existing title",
          description: "existing description",
          schema_name: "existing_schema",
        )
        described_class.create_or_replace(@item.base_path, { schema_name: "publication" })
      end

      it "updates the given attributes" do
        @item.reload
        expect(@item.schema_name).to eq("publication")
      end

      it "does not retain values of any attributes which were not given" do
        @item.reload
        expect(@item.title).to be_nil
        expect(@item["description"]).to eq("value" => nil)
      end
    end

    it "does not overwrite default attribute values if called with nil attributes" do
      _, item = described_class.create_or_replace(@item.base_path, { schema_name: "redirect", redirects: nil })
      expect(item.redirects).to eq([])
    end

    describe "exceptions" do
      context "when unknown attributes are provided" do
        let(:attributes) { { "foo" => "foo", "bar" => "bar" } }

        it "handles ActiveRecord::UnknownAttributeError" do
          result = item = nil

          expect {
            result, item = described_class.create_or_replace(@item.base_path, attributes)
          }.not_to raise_error

          expect(result).to be false
          expect(item.errors[:base]).to include("unrecognised field(s) foo, bar in input")
        end
      end

      context "when assigning a value of incorrect type" do
        let(:attributes) { { "routes" => 12 } }

        it "handles ActiveModel::ValidationError" do
          result = item = nil

          expect {
            # routes should be of type Array
            result, item = described_class.create_or_replace(@item.base_path, attributes)
          }.not_to raise_error

          expect(result).to be false
          expected_error_message = "Value of type Integer cannot be written to a field of type Array"
          expect(item.errors[:base].find { |e| e.include?(expected_error_message) }).not_to be_nil
        end
      end

      context "when UpdateLock raises an OutOfOrderTransmissionError" do
        before do
          allow_any_instance_of(UpdateLock)
            .to receive(:check_availability!)
            .and_raise(OutOfOrderTransmissionError, "Booyah")
        end

        it "returns a result of :conflict" do
          result, item = described_class.create_or_replace(@item.base_path, {})

          expect(result).to eq(:conflict)
          expect(item.errors[:message]).to include("Booyah")
        end
      end

      context "with current attributes and no previous item" do
        let(:attributes) { @item.attributes }

        it "saves the item" do
          result = item = nil
          expect {
            result, item = described_class.create_or_replace(@item.base_path, attributes)
          }.to change(described_class, :count).by(1)
          expect(result).to eq(:created)
        end
      end

      context "with current attributes and a previous item" do
        before do
          @item.save!
        end

        let(:attributes) { @item.attributes }

        it "saves the item" do
          result = item = nil
          expect {
            result, item = described_class.create_or_replace(@item.base_path, attributes)
          }.not_to change(described_class, :count)
          expect(result).to eq(:replaced)
        end
      end
    end
  end

  describe ".find_by_path" do
    subject { described_class.find_by_path(path) }

    it_behaves_like "find_by_path", :content_item
  end

  it "sets updated_at on save" do
    item = build(:content_item)
    Timecop.freeze do
      item.save!
      item.reload

      expect(item.updated_at.to_s).to eq(Time.zone.now.to_s)
    end
  end

  context "when loaded from the content store" do
    before do
      create(:content_item, base_path: "/base_path", routes: [{ "path" => "/base_path", "type" => "exact" }])
      @item = described_class.last
    end

    it "is valid" do
      expect(@item).to be_valid
    end
  end

  describe "#valid_auth_bypass_id?" do
    let(:auth_bypass_id) { SecureRandom.uuid }

    it "returns false for a nil input" do
      content_item = build(:content_item)
      expect(content_item.valid_auth_bypass_id?(nil)).to be(false)
    end

    it "returns true for an auth_bypass_id matching the content items one" do
      content_item = build(:content_item, auth_bypass_ids: [auth_bypass_id])

      expect(content_item.valid_auth_bypass_id?(auth_bypass_id)).to be(true)
    end

    it "returns true for an auth_bypass_id matching a linked items one" do
      content_item = build(
        :content_item,
        expanded_links: {
          "link_type" => [
            {
              "content_id" => SecureRandom.uuid,
              "auth_bypass_ids" => [auth_bypass_id],
            },
          ],
        },
      )

      expect(content_item.valid_auth_bypass_id?(auth_bypass_id)).to be(true)
    end

    it "returns false if no links have a matching auth_bypass_id" do
      content_item = build(
        :content_item,
        expanded_links: {
          "link_type" => [
            {
              "content_id" => SecureRandom.uuid,
              "auth_bypass_ids" => [SecureRandom.uuid],
            },
          ],
          "other_link" => [
            { "content_id" => SecureRandom.uuid },
          ],
        },
      )

      expect(content_item.valid_auth_bypass_id?(auth_bypass_id)).to be(false)
    end

    it "returns false if a link of a link has a matching auth_bypass_id" do
      nested_links = { "other_link" => [{ "content_id" => SecureRandom.uuid,
                                          "auth_bypass_id" => [auth_bypass_id] }] }
      links = { "link_type" => [{ "content_id" => SecureRandom.uuid,
                                  "links" => nested_links }] }
      content_item = build(:content_item, expanded_links: links)

      expect(content_item.valid_auth_bypass_id?(auth_bypass_id)).to be(false)
    end

    context "when auth_bypass_ids is nil" do
      let(:content_item) { build(:content_item, auth_bypass_ids: nil) }

      context "when given an auth_bypass_id" do
        let(:auth_bypass_id) { SecureRandom.uuid }

        it "does not raise an error" do
          expect { content_item.valid_auth_bypass_id?(auth_bypass_id) }.not_to raise_error
        end

        it "returns false" do
          expect(content_item.valid_auth_bypass_id?(auth_bypass_id)).to eq(false)
        end
      end
    end
  end

  describe "description" do
    context "when given a simple-valued description" do
      let(:description) { "foo" }

      it "wraps the description as a hash" do
        content_item = FactoryBot.create(:content_item, description:)

        expect(content_item.description).to eq("foo")
        expect(content_item["description"]).to eq("value" => "foo")
      end
    end

    context "when given a description that is already a Hash" do
      let(:description) { { "value" => "foo" } }

      it "does not wrap the description hash in another hash" do
        content_item = FactoryBot.create(:content_item, description:)

        expect(content_item.description).to eq("foo")
        expect(content_item["description"]).to eq("value" => "foo")
      end
    end
  end

  describe "gone?" do
    it "returns true for schema_name 'gone' with no details" do
      gone_item = build(:gone_content_item)
      expect(gone_item.gone?).to be(true)
    end

    it "returns false for schema_name 'gone' with details" do
      gone_item = build(:gone_content_item_with_details)
      expect(gone_item.gone?).to be(false)
    end

    it "returns true for schema_name 'gone' with empty details fields" do
      gone_item = build(:gone_content_time_with_empty_details_fields)
      expect(gone_item.gone?).to be(true)
    end
  end
end
