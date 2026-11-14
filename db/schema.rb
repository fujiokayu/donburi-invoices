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

ActiveRecord::Schema[8.0].define(version: 2026_11_08_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "organization_id"
    t.bigint "user_id"
    t.string "action", null: false
    t.string "target_type"
    t.bigint "target_id"
    t.string "ip"
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["action"], name: "index_audit_logs_on_action"
    t.index ["organization_id"], name: "index_audit_logs_on_organization_id"
    t.index ["target_type", "target_id"], name: "index_audit_logs_on_target_type_and_target_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "auth_logs", force: :cascade do |t|
    t.bigint "user_id"
    t.string "event", null: false
    t.string "email"
    t.string "ip"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.index ["email"], name: "index_auth_logs_on_email"
    t.index ["event"], name: "index_auth_logs_on_event"
    t.index ["user_id"], name: "index_auth_logs_on_user_id"
  end

  create_table "bank_accounts", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "bank_name", null: false
    t.string "branch_name"
    t.string "account_type"
    t.string "account_number", null: false
    t.string "holder_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_bank_accounts_on_organization_id"
  end

  create_table "invoice_lines", force: :cascade do |t|
    t.bigint "invoice_id", null: false
    t.string "description", null: false
    t.integer "quantity", default: 1, null: false
    t.integer "unit_price", default: 0, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invoice_id"], name: "index_invoice_lines_on_invoice_id"
  end

  create_table "invoices", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "bank_account_id"
    t.string "number", null: false
    t.string "customer_name", null: false
    t.integer "amount", default: 0, null: false
    t.string "status", default: "draft", null: false
    t.text "notes"
    t.date "due_on"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bank_account_id"], name: "index_invoices_on_bank_account_id"
    t.index ["organization_id", "number"], name: "index_invoices_on_organization_id_and_number", unique: true
    t.index ["organization_id"], name: "index_invoices_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.integer "invoice_seq", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "token", null: false
    t.string "ip"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_sessions_on_token", unique: true
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
  end

  add_foreign_key "audit_logs", "organizations"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "auth_logs", "users"
  add_foreign_key "bank_accounts", "organizations"
  add_foreign_key "invoice_lines", "invoices"
  add_foreign_key "invoices", "bank_accounts"
  add_foreign_key "invoices", "organizations"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "organizations"
end
