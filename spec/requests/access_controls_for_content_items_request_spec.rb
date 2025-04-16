require "rails_helper"

describe "Access controls for content items", type: :request do
  let!(:content_item) do
    create(
      :content_item,
      auth_bypass_ids: [content_auth_bypass_id],
      expanded_links: {
        related: [
          {
            content_id: SecureRandom.uuid,
            auth_bypass_ids: [linked_auth_bypass_id],
          },
        ],
      },
    )
  end

  let(:content_auth_bypass_id) { SecureRandom.uuid }
  let(:linked_auth_bypass_id) { SecureRandom.uuid }

  shared_examples "returns forbidden response" do
    it "returns a forbidden response" do
      get("/content/#{content_item.base_path}", headers:)

      json = JSON.parse(response.body)

      expect(response).to be_forbidden
      expect(json["errors"]["type"]).to eq("access_forbidden")
      expect(json["errors"]["code"]).to eq("403")
    end
  end

  shared_examples "returns private response" do
    it "returns a success response with private cache control" do
      get("/content/#{content_item.base_path}", headers:)

      json = JSON.parse(response.body)

      expect(response).to be_ok
      expect(json["title"]).to eq(content_item.title)
      expect(cache_control["private"]).to be true
    end
  end

  shared_examples "returns public response" do
    it "returns a success response with public cache control" do
      get("/content/#{content_item.base_path}", headers:)

      json = JSON.parse(response.body)

      expect(response).to be_ok
      expect(json["title"]).to eq(content_item.title)
      expect(cache_control["public"]).to be true
    end
  end

  context "when the contents auth bypass id is included" do
    let(:headers) do
      {
        "X-Publishing-Platform-Authenticated-User-Organisation" => SecureRandom.uuid,
        "Publishing-Platform-Auth-Bypass-Id" => content_auth_bypass_id,
      }
    end

    include_examples "returns private response"
  end

  context "when the linked auth bypass id is included" do
    let(:headers) do
      {
        "X-Publishing-Platform-Authenticated-User-Organisation" => SecureRandom.uuid,
        "Publishing-Platform-Auth-Bypass-Id" => linked_auth_bypass_id,
      }
    end

    include_examples "returns private response"
  end

  context "when the user is signed in and an incorrect auth bypass id is included" do
    let(:headers) do
      {
        "X-Publishing-Platform-Authenticated-User" => SecureRandom.uuid,
        "Publishing-Platform-Auth-Bypass-Id" => SecureRandom.uuid,
      }
    end

    include_examples "returns private response"
  end

  context "when the user is not signed in and an incorrect auth bypass id is included" do
    let(:headers) do
      {
        "X-Publishing-Platform-Authenticated-User" => "invalid",
        "Publishing-Platform-Auth-Bypass-Id" => SecureRandom.uuid,
      }
    end

    include_examples "returns forbidden response"
  end

  context "when the user is not signed in and an auth bypass id is not included" do
    let(:headers) { {} }

    include_examples "returns public response"
  end
end
