# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_12_07_035653) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "demux_access_keys", force: :cascade do |t|
    t.text "public_key", null: false
    t.integer "app_id", null: false
    t.string "fingerprint", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id"], name: "index_demux_access_keys_on_app_id"
  end

  create_table "demux_apps", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "secret"
    t.string "entry_url"
    t.string "signal_url"
    t.text "signals", default: [], array: true
    t.text "account_types", default: [], array: true
    t.jsonb "configuration", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "indicator"
    t.index ["configuration"], name: "index_demux_apps_on_configuration", using: :gin
    t.index ["secret"], name: "index_demux_apps_on_secret", unique: true
    t.index ["signals"], name: "index_demux_apps_on_signals", using: :gin
  end

  create_table "demux_connections", force: :cascade do |t|
    t.integer "account_id"
    t.string "account_type"
    t.integer "app_id"
    t.text "signals", default: [], array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "account_type"], name: "index_demux_connections_on_account_id_and_account_type"
    t.index ["app_id"], name: "index_demux_connections_on_app_id"
    t.index ["signals"], name: "index_demux_connections_on_signals", using: :gin
  end

  create_table "demux_transmissions", force: :cascade do |t|
    t.string "signal_class"
    t.string "action"
    t.integer "object_id"
    t.integer "app_id"
    t.integer "account_id"
    t.string "account_type"
    t.integer "status", default: 0
    t.string "response_code"
    t.jsonb "response_headers"
    t.text "response_body"
    t.jsonb "context"
    t.jsonb "request_headers"
    t.text "request_body"
    t.string "request_url"
    t.string "uniqueness_hash"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["app_id"], name: "index_demux_transmissions_on_app_id"
    t.index ["uniqueness_hash", "app_id"], name: "index_demux_transmissions_on_uniqueness_hash_and_app_id", unique: true, where: "(status = 0)"
  end

  create_table "lessons", force: :cascade do |t|
    t.string "name"
    t.boolean "public"
    t.integer "company_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
