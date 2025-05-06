class CreateBoardHistories < ActiveRecord::Migration[7.0]
  def change
    create_table :board_histories do |t|
      t.references :game, null: false, foreign_key: true
      t.string :sfen, null: false
      t.integer :move_number, null: false
      t.string :branch, default: 'main'
      t.timestamps
    end
    
    add_index :board_histories, [:game_id, :move_number, :branch], unique: true
  end
end