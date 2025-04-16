require "rails_helper"

describe "End-to-end behaviour", type: :request do
  let(:data) do
    {
      "base_path" => "/vat-rates",
      "content_id" => SecureRandom.uuid,
      "title" => "VAT rates",
      "schema_name" => "answer",
      "document_type" => "answer",
      "publishing_app" => "publisher",
      "rendering_app" => "frontend",
      "routes" => [
        { "path" => "/vat-rates", "type" => "exact" },
      ],
      "public_updated_at" => Time.zone.now,
      "payload_version" => "1",
    }
  end

  def create_item(data_hash)
    put_json "/content#{data_hash['base_path']}", data_hash
    expect(response.status).to eq(201)
  end

  it "should allow items to be added and retrieved" do
    create_item(data)

    get "/content/vat-rates"
    expect(response.status).to eq(200)
    expect(response.media_type).to eq("application/json")
    response_data = JSON.parse(response.body)

    expect(response_data["title"]).to eq("VAT rates")
    # More detailed checks in fetching_content_item_spec
  end
end
