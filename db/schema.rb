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

ActiveRecord::Schema[8.0].define(version: 2025_07_09_024158) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "device_api_requests", force: :cascade do |t|
    t.bigint "device_id", null: false
    t.string "sidekiq_job_id"
    t.integer "status", default: 0, null: false
    t.jsonb "request_payload"
    t.string "api_endpoint"
    t.datetime "processed_at"
    t.datetime "completed_at"
    t.text "error_message"
    t.text "stack_trace"
    t.integer "retries_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_device_api_requests_on_device_id"
    t.index ["sidekiq_job_id"], name: "index_device_api_requests_on_sidekiq_job_id", unique: true, where: "(sidekiq_job_id IS NOT NULL)"
    t.index ["status"], name: "index_device_api_requests_on_status"
  end

  create_table "device_types", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_device_types_on_name", unique: true
  end

  create_table "device_updates", force: :cascade do |t|
    t.bigint "device_id", null: false
    t.integer "last_update_status", default: 1, null: false
    t.integer "operational_status", default: 0, null: false
    t.datetime "last_updated_at"
    t.datetime "last_sync_time"
    t.string "current_firmware_version"
    t.string "desired_firmware_version"
    t.bigint "last_successful_request_id"
    t.bigint "last_failed_request_id"
    t.text "last_error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_device_updates_on_device_id"
    t.index ["last_failed_request_id"], name: "index_device_updates_on_last_failed_request_id"
    t.index ["last_successful_request_id"], name: "index_device_updates_on_last_successful_request_id"
    t.index ["last_update_status"], name: "index_device_updates_on_last_update_status"
    t.index ["operational_status"], name: "index_device_updates_on_operational_status"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "device_type_id", null: false
    t.string "uuid", null: false
    t.string "name"
    t.string "manufacturer"
    t.string "model"
    t.string "serial_number"
    t.string "firmware_version"
    t.datetime "last_connection_at"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_devices_on_active"
    t.index ["device_type_id"], name: "index_devices_on_device_type_id"
    t.index ["serial_number"], name: "index_devices_on_serial_number", unique: true, where: "(serial_number IS NOT NULL)"
  end

  create_table "local_devices", force: :cascade do |t|
    t.bigint "local_id", null: false
    t.bigint "device_id", null: false
    t.datetime "assigned_from"
    t.datetime "assigned_until"
    t.boolean "is_current"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id", "is_current"], name: "index_local_devices_on_device_id_and_is_current", unique: true, where: "(is_current = true)"
    t.index ["device_id"], name: "index_local_devices_on_device_id"
    t.index ["local_id"], name: "index_local_devices_on_local_id"
  end

  create_table "locals", force: :cascade do |t|
    t.string "name", null: false
    t.string "address"
    t.string "city"
    t.string "region"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_locals_on_name", unique: true
  end

  add_foreign_key "device_api_requests", "devices"
  add_foreign_key "device_updates", "device_api_requests", column: "last_failed_request_id"
  add_foreign_key "device_updates", "device_api_requests", column: "last_successful_request_id"
  add_foreign_key "device_updates", "devices"
  add_foreign_key "devices", "device_types"
  add_foreign_key "local_devices", "devices"
  add_foreign_key "local_devices", "locals"
end
