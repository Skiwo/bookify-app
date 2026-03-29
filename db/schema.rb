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

ActiveRecord::Schema[8.0].define(version: 2026_03_29_000009) do
  create_schema "_heroku"

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_stat_statements"
  enable_extension "pgcrypto"

  create_table "bookings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "engagement_id", null: false
    t.string "description", null: false
    t.string "occupation_code"
    t.integer "status", default: 0, null: false
    t.integer "rate_ore", null: false
    t.decimal "hours", precision: 8, scale: 2, null: false
    t.date "work_date"
    t.string "order_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "booking_type", default: 0, null: false
    t.time "start_time"
    t.time "end_time"
    t.date "work_start_date"
    t.date "work_end_date"
    t.decimal "total_hours", precision: 8, scale: 2
    t.index ["engagement_id"], name: "index_bookings_on_engagement_id"
    t.index ["status"], name: "index_bookings_on_status"
  end

  create_table "engagements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "booker_id", null: false
    t.uuid "freelancer_id"
    t.string "name", null: false
    t.string "email", null: false
    t.string "pop_worker_id"
    t.string "pop_enrollment_id"
    t.integer "status", default: 0, null: false
    t.jsonb "pop_profile_data", default: {}
    t.string "invitation_token"
    t.datetime "invited_at"
    t.datetime "onboarded_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booker_id", "email"], name: "index_engagements_on_booker_id_and_email", unique: true
    t.index ["booker_id"], name: "index_engagements_on_booker_id"
    t.index ["freelancer_id"], name: "index_engagements_on_freelancer_id"
    t.index ["invitation_token"], name: "index_engagements_on_invitation_token", unique: true
    t.index ["pop_worker_id"], name: "index_engagements_on_pop_worker_id"
  end

  create_table "passwordless_sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "authenticatable_type"
    t.uuid "authenticatable_id"
    t.datetime "timeout_at", null: false
    t.datetime "expires_at", null: false
    t.datetime "claimed_at"
    t.text "token_digest", null: false
    t.string "identifier", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["authenticatable_type", "authenticatable_id"], name: "authenticatable"
  end

  create_table "payouts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "booking_id", null: false
    t.string "pop_payout_id"
    t.string "pop_status"
    t.integer "amount_ore"
    t.string "pop_invoice_number"
    t.jsonb "pop_response", default: {}
    t.datetime "synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payouts_on_booking_id", unique: true
    t.index ["pop_payout_id"], name: "index_payouts_on_pop_payout_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "email", null: false
    t.string "name"
    t.integer "role", default: 0, null: false
    t.datetime "last_sign_in_at"
    t.boolean "welcome_dismissed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pop_sandbox_api_key"
    t.string "pop_sandbox_hmac_secret"
    t.string "pop_sandbox_partner_id"
    t.string "pop_environment", default: "sandbox", null: false
    t.string "pop_production_api_key"
    t.string "pop_production_hmac_secret"
    t.string "pop_production_partner_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "bookings", "engagements"
  add_foreign_key "engagements", "users", column: "booker_id"
  add_foreign_key "engagements", "users", column: "freelancer_id"
  add_foreign_key "payouts", "bookings"
end
