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

ActiveRecord::Schema[8.1].define(version: 2026_09_05_061217) do
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

  create_table "backgrounds", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "orientation", default: "landscape", null: false
    t.integer "ratings_count", default: 0, null: false
    t.integer "ratings_sum", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["status"], name: "index_backgrounds_on_status"
    t.index ["user_id"], name: "index_backgrounds_on_user_id"
  end

  create_table "ratings", force: :cascade do |t|
    t.integer "background_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "value", null: false
    t.index ["background_id"], name: "index_ratings_on_background_id"
    t.index ["user_id", "background_id"], name: "index_ratings_on_user_id_and_background_id", unique: true
    t.index ["user_id"], name: "index_ratings_on_user_id"
  end

  create_table "saved_noshis", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "settings", default: {}, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_saved_noshis_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_period_end"
    t.string "status", default: "incomplete", null: false
    t.string "stripe_price_id"
    t.string "stripe_subscription_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "uchujin_check_ins", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "expected_every_seconds"
    t.datetime "last_seen_at"
    t.json "metadata", default: {}
    t.string "name", null: false
    t.integer "ping_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_uchujin_check_ins_on_name", unique: true
  end

  create_table "uchujin_comments", force: :cascade do |t|
    t.bigint "author_id"
    t.string "author_name"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "fault_id", null: false
    t.datetime "updated_at", null: false
    t.index ["fault_id"], name: "index_uchujin_comments_on_fault_id"
  end

  create_table "uchujin_deployments", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deployed_at", null: false
    t.string "environment", null: false
    t.json "metadata", default: {}
    t.string "repository"
    t.string "sha", null: false
    t.datetime "updated_at", null: false
    t.string "user"
    t.index ["environment", "deployed_at"], name: "index_uchujin_deployments_on_environment_and_deployed_at"
  end

  create_table "uchujin_faults", force: :cascade do |t|
    t.bigint "assignee_id"
    t.string "class_name", null: false
    t.string "component", default: "web", null: false
    t.datetime "created_at", null: false
    t.string "environment", null: false
    t.string "fingerprint", null: false
    t.datetime "first_seen_at"
    t.datetime "last_notified_at"
    t.datetime "last_seen_at"
    t.text "message"
    t.integer "occurrences_count", default: 0, null: false
    t.datetime "resolved_at"
    t.string "revision"
    t.json "sample_context", default: {}
    t.string "status", default: "unresolved", null: false
    t.json "tags", default: []
    t.datetime "updated_at", null: false
    t.index ["class_name"], name: "index_uchujin_faults_on_class_name"
    t.index ["component"], name: "index_uchujin_faults_on_component"
    t.index ["environment"], name: "index_uchujin_faults_on_environment"
    t.index ["fingerprint"], name: "index_uchujin_faults_on_fingerprint", unique: true
    t.index ["last_seen_at"], name: "index_uchujin_faults_on_last_seen_at"
    t.index ["status"], name: "index_uchujin_faults_on_status"
  end

  create_table "uchujin_notifications", force: :cascade do |t|
    t.string "channel", null: false
    t.datetime "created_at", null: false
    t.integer "fault_id"
    t.json "payload", default: {}
    t.datetime "sent_at"
    t.string "status", default: "sent"
    t.datetime "updated_at", null: false
    t.index ["fault_id"], name: "index_uchujin_notifications_on_fault_id"
  end

  create_table "uchujin_occurrences", force: :cascade do |t|
    t.json "backtrace", default: []
    t.json "backtrace_app", default: []
    t.json "breadcrumbs", default: []
    t.json "cause"
    t.json "client_info", default: {}
    t.string "component"
    t.json "context", default: {}
    t.datetime "created_at", null: false
    t.string "environment"
    t.integer "fault_id", null: false
    t.text "message"
    t.datetime "occurred_at", null: false
    t.json "params", default: {}
    t.json "request_metadata", default: {}
    t.string "revision"
    t.json "server_stats", default: {}
    t.json "source_context_lines", default: []
    t.datetime "updated_at", null: false
    t.index ["fault_id"], name: "index_uchujin_occurrences_on_fault_id"
    t.index ["occurred_at"], name: "index_uchujin_occurrences_on_occurred_at"
  end

  create_table "uchujin_uptime_checks", force: :cascade do |t|
    t.datetime "checked_at", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.integer "response_time_ms"
    t.string "status", default: "unknown", null: false
    t.integer "status_code"
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["url", "checked_at"], name: "index_uchujin_uptime_checks_on_url_and_checked_at"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name"
    t.string "provider", null: false
    t.string "stripe_customer_id"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["stripe_customer_id"], name: "index_users_on_stripe_customer_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "backgrounds", "users"
  add_foreign_key "ratings", "backgrounds"
  add_foreign_key "ratings", "users"
  add_foreign_key "saved_noshis", "users"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "uchujin_comments", "uchujin_faults", column: "fault_id"
  add_foreign_key "uchujin_notifications", "uchujin_faults", column: "fault_id"
  add_foreign_key "uchujin_occurrences", "uchujin_faults", column: "fault_id"
end
