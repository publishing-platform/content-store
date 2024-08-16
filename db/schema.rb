# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_08_16_120155) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "content_items", force: :cascade do |t|
    t.string "base_path"
    t.string "content_id"
    t.string "title"
    t.jsonb "description", default: {"value"=>nil}
    t.string "document_type"
    t.string "schema_name"
    t.datetime "first_published_at"
    t.datetime "public_updated_at"
    t.jsonb "details", default: {}
    t.string "publishing_app"
    t.string "rendering_app"
    t.jsonb "routes", default: []
    t.jsonb "redirects", default: []
    t.jsonb "expanded_links", default: {}
    t.string "auth_bypass_ids", default: [], array: true
    t.string "phase", default: "live"
    t.integer "payload_version"
    t.jsonb "withdrawn_notice", default: {}
    t.string "publishing_request_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_path"], name: "index_content_items_on_base_path", unique: true
    t.index ["content_id"], name: "index_content_items_on_content_id"
    t.index ["created_at"], name: "index_content_items_on_created_at"
    t.index ["redirects"], name: "index_content_items_on_redirects", using: :gin
    t.index ["redirects"], name: "ix_ci_redirects_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
    t.index ["routes"], name: "index_content_items_on_routes", using: :gin
    t.index ["routes"], name: "ix_ci_routes_jsonb_path_ops", opclass: :jsonb_path_ops, using: :gin
    t.index ["updated_at"], name: "index_content_items_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid"
    t.string "organisation_slug"
    t.string "organisation_content_id"
    t.text "permissions"
    t.boolean "disabled", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
