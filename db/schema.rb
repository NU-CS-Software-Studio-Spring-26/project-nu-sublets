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

ActiveRecord::Schema[8.1].define(version: 2026_05_28_010000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "listing_questions", force: :cascade do |t|
    t.text "answer"
    t.datetime "answered_at"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "sublet_listing_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["sublet_listing_id"], name: "index_listing_questions_on_sublet_listing_id"
    t.index ["user_id"], name: "index_listing_questions_on_user_id"
  end

  create_table "listing_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.string "status", default: "open", null: false
    t.integer "sublet_listing_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["status"], name: "index_listing_reports_on_status"
    t.index ["sublet_listing_id"], name: "index_listing_reports_on_sublet_listing_id"
    t.index ["user_id"], name: "index_listing_reports_on_user_id"
  end

  create_table "sublet_listings", force: :cascade do |t|
    t.text "address", null: false
    t.text "amenities"
    t.date "available_from", null: false
    t.date "available_until", null: false
    t.integer "bathrooms", null: false
    t.integer "bedrooms", null: false
    t.datetime "created_at", null: false
    t.text "description", null: false
    t.boolean "furnished", default: false, null: false
    t.boolean "pets_allowed", default: false, null: false
    t.text "preferences"
    t.decimal "price", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.boolean "utilities_included", default: false, null: false
    t.index ["user_id"], name: "index_sublet_listings_on_user_id"
    t.check_constraint "available_until > available_from", name: "sublet_listings_available_until_after_from"
    t.check_constraint "bathrooms >= 0 AND bathrooms <= 20", name: "sublet_listings_bathrooms_range"
    t.check_constraint "bedrooms >= 0 AND bedrooms <= 20", name: "sublet_listings_bedrooms_range"
    t.check_constraint "price > 0 AND price <= 20000", name: "sublet_listings_price_range"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active"
    t.text "bio"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "name"
    t.string "password_digest"
    t.string "profile_photo_url"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true, where: "provider IS NOT NULL AND uid IS NOT NULL"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "listing_questions", "sublet_listings"
  add_foreign_key "listing_questions", "users"
  add_foreign_key "listing_reports", "sublet_listings"
  add_foreign_key "listing_reports", "users"
  add_foreign_key "sublet_listings", "users"
end
