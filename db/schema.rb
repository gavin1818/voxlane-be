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

ActiveRecord::Schema[7.2].define(version: 2026_03_07_190813) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "billing_customers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "external_customer_id", null: false
    t.boolean "livemode", default: false, null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "external_customer_id"], name: "index_billing_customers_on_provider_and_external_customer_id", unique: true
    t.index ["user_id", "provider"], name: "index_billing_customers_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_billing_customers_on_user_id"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "device_identifier", null: false
    t.string "platform"
    t.string "app_version"
    t.datetime "last_seen_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "device_identifier"], name: "index_devices_on_user_id_and_device_identifier", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "entitlements", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "key", null: false
    t.string "status", null: false
    t.string "source", null: false
    t.datetime "active_from"
    t.datetime "active_until"
    t.datetime "trial_ends_at"
    t.datetime "last_synced_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "key"], name: "index_entitlements_on_user_id_and_key", unique: true
    t.index ["user_id"], name: "index_entitlements_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "billing_customer_id", null: false
    t.string "provider", null: false
    t.string "external_subscription_id", null: false
    t.string "external_price_id"
    t.string "status", null: false
    t.datetime "current_period_end_at"
    t.boolean "cancel_at_period_end", default: false, null: false
    t.datetime "canceled_at"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["billing_customer_id"], name: "index_subscriptions_on_billing_customer_id"
    t.index ["provider", "external_subscription_id"], name: "index_subscriptions_on_provider_and_external_subscription_id", unique: true
    t.index ["user_id", "provider"], name: "index_subscriptions_on_user_id_and_provider"
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "supabase_uid", null: false
    t.string "email"
    t.string "display_name"
    t.datetime "last_seen_at"
    t.jsonb "profile", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["supabase_uid"], name: "index_users_on_supabase_uid", unique: true
  end

  create_table "webhook_events", force: :cascade do |t|
    t.string "provider", null: false
    t.string "external_event_id", null: false
    t.string "event_type", null: false
    t.jsonb "payload", default: {}, null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "external_event_id"], name: "index_webhook_events_on_provider_and_external_event_id", unique: true
  end

  add_foreign_key "billing_customers", "users"
  add_foreign_key "devices", "users"
  add_foreign_key "entitlements", "users"
  add_foreign_key "subscriptions", "billing_customers"
  add_foreign_key "subscriptions", "users"
end
