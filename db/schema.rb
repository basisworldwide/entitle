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

ActiveRecord::Schema[7.1].define(version: 2024_05_22_094703) do
  create_table "activity_logs", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.integer "created_by", null: false
    t.string "description", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "companies", force: :cascade do |t|
    t.string "name", null: false
    t.string "logo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_companies_on_name", unique: true
  end

  create_table "company_integrations", force: :cascade do |t|
    t.integer "company_id", null: false
    t.integer "integration_id", null: false
    t.string "access_token", null: false
    t.string "refresh_token", null: false
    t.string "status", default: "active", null: false
    t.integer "companies_id"
    t.integer "integrations_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["companies_id"], name: "index_company_integrations_on_companies_id"
    t.index ["integrations_id"], name: "index_company_integrations_on_integrations_id"
  end

  create_table "employee_integrations", force: :cascade do |t|
    t.integer "employee_id", null: false
    t.integer "integration_id", null: false
    t.string "accunt_type", null: false
    t.datetime "start_date"
    t.datetime "end_date"
    t.integer "employees_id"
    t.integer "integrations_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employees_id"], name: "index_employee_integrations_on_employees_id"
    t.index ["integrations_id"], name: "index_employee_integrations_on_integrations_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "company_id", null: false
    t.string "image"
    t.string "designation", null: false
    t.string "phone", null: false
    t.datetime "joining_date"
    t.string "employee_id", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.integer "companies_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["companies_id"], name: "index_employees_on_companies_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
  end

  create_table "error_logs", force: :cascade do |t|
    t.string "url", null: false
    t.string "payload", null: false
    t.string "description", null: false
    t.integer "created_by"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "integrations", force: :cascade do |t|
    t.string "name", null: false
    t.string "description", null: false
    t.string "logo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_integrations_on_name", unique: true
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "phone", default: "", null: false
    t.datetime "joining_date", null: false
    t.integer "company_id", default: 0, null: false
    t.integer "role_id", default: 0, null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "activity_logs", "employees"
  add_foreign_key "activity_logs", "users", column: "created_by"
  add_foreign_key "company_integrations", "companies", column: "companies_id"
  add_foreign_key "company_integrations", "integrations", column: "integrations_id"
  add_foreign_key "employee_integrations", "employees", column: "employees_id"
  add_foreign_key "employee_integrations", "integrations", column: "integrations_id"
  add_foreign_key "employees", "companies", column: "companies_id"
  add_foreign_key "error_logs", "users", column: "created_by"
  add_foreign_key "users", "companies"
  add_foreign_key "users", "roles"
end
