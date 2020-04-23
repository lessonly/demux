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

ActiveRecord::Schema.define(version: 2020_04_23_144102) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "demux_apps", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "secret"
    t.string "entry_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["secret"], name: "index_demux_apps_on_secret", unique: true
  end

  create_table "demux_connections", force: :cascade do |t|
    t.integer "account_id"
    t.integer "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_demux_connections_on_account_id"
    t.index ["app_id"], name: "index_demux_connections_on_app_id"
  end

end
