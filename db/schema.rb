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

ActiveRecord::Schema[8.0].define(version: 2026_04_28_200001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "booking_lines", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "booking_id", null: false
    t.string "description", null: false
    t.string "occupation_code"
    t.integer "booking_type", default: 0, null: false
    t.integer "rate_ore", null: false
    t.decimal "hours", precision: 8, scale: 2
    t.date "work_date"
    t.time "start_time"
    t.time "end_time"
    t.decimal "total_hours", precision: 8, scale: 2
    t.date "work_start_date"
    t.date "work_end_date"
    t.string "line_external_id"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "line_type", default: 0, null: false
    t.string "receipt_url"
    t.index ["booking_id", "position"], name: "index_booking_lines_on_booking_id_and_position"
  end

  create_table "bookings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "enrollment_id"
    t.string "description"
    t.integer "status", default: 0, null: false
    t.string "order_reference"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "invoiced_on"
    t.date "due_on"
    t.string "buyer_reference"
    t.text "external_note"
    t.index ["enrollment_id"], name: "index_bookings_on_enrollment_id"
    t.index ["status"], name: "index_bookings_on_status"
  end

  create_table "clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id"
    t.string "org_number", null: false
    t.string "org_name", null: false
    t.string "org_address"
    t.datetime "verified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "bookify_fee_enabled", default: false, null: false
    t.index ["org_number"], name: "index_clients_on_org_number", unique: true
    t.index ["user_id"], name: "index_clients_on_user_id"
  end

  create_table "disputes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "job_id", null: false
    t.uuid "raised_by_id", null: false
    t.text "reason", null: false
    t.integer "status", default: 0, null: false
    t.datetime "resolved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "response"
    t.uuid "responded_by_id"
    t.datetime "responded_at"
    t.text "resolution"
    t.uuid "resolved_by_id"
    t.index ["job_id"], name: "index_disputes_on_job_id"
    t.index ["raised_by_id"], name: "index_disputes_on_raised_by_id"
    t.index ["resolved_by_id"], name: "index_disputes_on_resolved_by_id"
    t.index ["responded_by_id"], name: "index_disputes_on_responded_by_id"
  end

  create_table "enrollments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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
    t.index ["booker_id", "email"], name: "index_enrollments_on_booker_id_and_email", unique: true
    t.index ["freelancer_id"], name: "index_enrollments_on_freelancer_id"
    t.index ["invitation_token"], name: "index_enrollments_on_invitation_token", unique: true
    t.index ["pop_worker_id"], name: "index_enrollments_on_pop_worker_id"
  end

  create_table "freelancer_educations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "institution", null: false
    t.string "degree"
    t.string "field_of_study"
    t.integer "graduation_year"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_freelancer_educations_on_user_id"
  end

  create_table "freelancer_experiences", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.string "title", null: false
    t.string "company", null: false
    t.text "description"
    t.date "started_on", null: false
    t.date "ended_on"
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_freelancer_experiences_on_user_id"
  end

  create_table "job_reads", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "job_id", null: false
    t.uuid "user_id", null: false
    t.datetime "last_read_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id", "user_id"], name: "index_job_reads_on_job_id_and_user_id", unique: true
    t.index ["job_id"], name: "index_job_reads_on_job_id"
    t.index ["user_id"], name: "index_job_reads_on_user_id"
  end

  create_table "jobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shop_id", null: false
    t.uuid "client_id", null: false
    t.uuid "assigned_member_id"
    t.uuid "booking_id"
    t.string "title", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.integer "work_amount_ore"
    t.integer "commission_amount_ore"
    t.datetime "quote_expires_at"
    t.datetime "completion_marked_at"
    t.datetime "confirmation_deadline_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "shop_completed_at"
    t.datetime "client_completed_at"
    t.date "work_date"
    t.decimal "work_hours", precision: 5, scale: 2
    t.integer "rate_per_hour_ore"
    t.decimal "estimated_hours", precision: 5, scale: 2
    t.date "desired_date"
    t.decimal "desired_hours", precision: 5, scale: 2
    t.datetime "member_accepted_at"
    t.index ["assigned_member_id"], name: "index_jobs_on_assigned_member_id"
    t.index ["booking_id"], name: "index_jobs_on_booking_id"
    t.index ["client_id"], name: "index_jobs_on_client_id"
    t.index ["shop_id"], name: "index_jobs_on_shop_id"
    t.index ["status"], name: "index_jobs_on_status"
  end

  create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "job_id", null: false
    t.uuid "sender_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "system_message", default: false, null: false
    t.index ["job_id", "created_at"], name: "index_messages_on_job_id_and_created_at"
    t.index ["job_id"], name: "index_messages_on_job_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
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
    t.index ["authenticatable_type", "authenticatable_id"], name: "index_passwordless_on_authenticatable"
    t.index ["identifier"], name: "index_passwordless_sessions_on_identifier"
    t.index ["token_digest"], name: "index_passwordless_sessions_on_token_digest"
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

  create_table "quote_lines", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "job_id", null: false
    t.string "description", null: false
    t.integer "rate_ore", null: false
    t.decimal "hours", precision: 5, scale: 2, default: "1.0", null: false
    t.integer "amount_ore", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "index_quote_lines_on_job_id"
  end

  create_table "shop_invitations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shop_id", null: false
    t.string "email", null: false
    t.string "token", null: false
    t.datetime "accepted_at"
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "email"], name: "index_shop_invitations_on_shop_id_and_email", unique: true
    t.index ["shop_id"], name: "index_shop_invitations_on_shop_id"
    t.index ["token"], name: "index_shop_invitations_on_token", unique: true
  end

  create_table "shop_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shop_id", null: false
    t.uuid "enrollment_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "invited_at"
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invitation_token"
    t.string "bookify_pop_worker_id"
    t.index ["bookify_pop_worker_id"], name: "index_shop_members_on_bookify_pop_worker_id"
    t.index ["enrollment_id"], name: "index_shop_members_on_enrollment_id"
    t.index ["invitation_token"], name: "index_shop_members_on_invitation_token", unique: true
    t.index ["shop_id", "enrollment_id"], name: "index_shop_members_on_shop_id_and_enrollment_id", unique: true
    t.index ["shop_id"], name: "index_shop_members_on_shop_id"
  end

  create_table "shop_skills", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "shop_id", null: false
    t.uuid "skill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "skill_id"], name: "index_shop_skills_on_shop_id_and_skill_id", unique: true
    t.index ["shop_id"], name: "index_shop_skills_on_shop_id"
    t.index ["skill_id"], name: "index_shop_skills_on_skill_id"
  end

  create_table "shops", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "owner_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.integer "visibility", default: 0, null: false
    t.integer "commission_percent", default: 5, null: false
    t.string "city"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "pop_worker_id"
    t.boolean "solo", default: false, null: false
    t.index ["owner_id"], name: "index_shops_on_owner_id", unique: true
    t.index ["slug"], name: "index_shops_on_slug", unique: true
    t.index ["status"], name: "index_shops_on_status"
    t.index ["visibility"], name: "index_shops_on_visibility"
  end

  create_table "skills", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "slug", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_skills_on_position"
    t.index ["slug"], name: "index_skills_on_slug", unique: true
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
    t.datetime "last_online_at"
    t.string "locale", default: "nb", null: false
    t.string "headline"
    t.text "bio"
    t.string "location"
    t.integer "hourly_rate_ore"
    t.string "experience_level"
    t.boolean "profile_public", default: false, null: false
    t.string "profile_slug"
    t.string "profile_skill_tags", default: [], array: true
    t.string "bookify_pop_worker_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["profile_slug"], name: "index_users_on_profile_slug", unique: true, where: "(profile_slug IS NOT NULL)"
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "booking_lines", "bookings"
  add_foreign_key "bookings", "enrollments"
  add_foreign_key "clients", "users"
  add_foreign_key "disputes", "jobs"
  add_foreign_key "disputes", "users", column: "raised_by_id"
  add_foreign_key "disputes", "users", column: "resolved_by_id"
  add_foreign_key "disputes", "users", column: "responded_by_id"
  add_foreign_key "enrollments", "users", column: "booker_id"
  add_foreign_key "enrollments", "users", column: "freelancer_id"
  add_foreign_key "freelancer_educations", "users"
  add_foreign_key "freelancer_experiences", "users"
  add_foreign_key "job_reads", "jobs"
  add_foreign_key "job_reads", "users"
  add_foreign_key "jobs", "bookings"
  add_foreign_key "jobs", "clients"
  add_foreign_key "jobs", "shop_members", column: "assigned_member_id"
  add_foreign_key "jobs", "shops"
  add_foreign_key "messages", "jobs"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "payouts", "bookings"
  add_foreign_key "quote_lines", "jobs"
  add_foreign_key "shop_invitations", "shops"
  add_foreign_key "shop_members", "enrollments"
  add_foreign_key "shop_members", "shops"
  add_foreign_key "shop_skills", "shops"
  add_foreign_key "shop_skills", "skills"
  add_foreign_key "shops", "users", column: "owner_id"
end
