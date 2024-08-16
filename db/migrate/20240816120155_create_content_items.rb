class CreateContentItems < ActiveRecord::Migration[7.1]
  def change
    create_table :content_items do |t|
      t.string :base_path
      t.string :content_id
      t.string :title
      t.jsonb :description, default: { "value" => nil }
      t.string :document_type
      t.string :schema_name
      t.datetime :first_published_at
      t.datetime :public_updated_at
      t.jsonb :details, default: {}
      t.string :publishing_app
      t.string :rendering_app
      t.jsonb :routes, default: []
      t.jsonb :redirects, default: []
      t.jsonb :expanded_links, default: {}
      t.string :auth_bypass_ids, array: true, default: []
      t.string :phase, default: "live"
      t.integer :payload_version
      t.jsonb :withdrawn_notice, default: {}
      t.string :publishing_request_id, null: true, default: nil

      t.timestamps
    end

    add_index :content_items, :base_path, unique: true
    add_index :content_items, :content_id
    add_index :content_items, :created_at
    add_index :content_items, :updated_at
    add_index :content_items, :routes, using: :gin
    add_index :content_items, :redirects, using: :gin
    add_index :content_items, :routes, using: :gin, opclass: :jsonb_path_ops, name: "ix_ci_routes_jsonb_path_ops"
    add_index :content_items, :redirects, using: :gin, opclass: :jsonb_path_ops, name: "ix_ci_redirects_jsonb_path_ops"
  end
end
