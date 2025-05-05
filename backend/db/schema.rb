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

ActiveRecord::Schema[7.0].define(version: 2025_05_05_080241) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "board_histories", force: :cascade do |t|
    t.bigint "game_id", null: false
    t.string "sfen", null: false
    t.integer "move_number", null: false
    t.string "branch", default: "main"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "move_sfen"
    t.index ["game_id", "move_number", "branch"], name: "index_board_histories_on_game_id_and_move_number_and_branch", unique: true
    t.index ["game_id"], name: "index_board_histories_on_game_id"
  end

  create_table "boards", force: :cascade do |t|
    t.string "sfen", default: "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "game_id", null: false
    t.boolean "custom_position", default: false
    t.index ["custom_position"], name: "index_boards_on_custom_position"
    t.index ["game_id"], name: "index_boards_on_game_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "board_history_id", null: false
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["board_history_id"], name: "idx_comments_board_history"
    t.index ["board_history_id"], name: "idx_comments_board_history_id"
  end

  create_table "games", force: :cascade do |t|
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "winner"
    t.datetime "ended_at"
    t.bigint "black_player_id"
    t.bigint "white_player_id"
    t.string "mode", default: "play", null: false
    t.index ["black_player_id"], name: "index_games_on_black_player_id"
    t.index ["white_player_id"], name: "index_games_on_white_player_id"
  end

  create_table "pieces", force: :cascade do |t|
    t.bigint "board_id", null: false
    t.integer "position_x"
    t.integer "position_y"
    t.string "piece_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "owner"
    t.boolean "promoted"
    t.index ["board_id"], name: "index_pieces_on_board_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "board_histories", "games"
  add_foreign_key "boards", "games"
  add_foreign_key "comments", "board_histories"
  add_foreign_key "games", "users", column: "black_player_id"
  add_foreign_key "games", "users", column: "white_player_id"
  add_foreign_key "pieces", "boards"
end
