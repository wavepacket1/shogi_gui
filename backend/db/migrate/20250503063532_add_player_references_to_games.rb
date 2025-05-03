class AddPlayerReferencesToGames < ActiveRecord::Migration[7.0]
  def change
    add_reference :games, :black_player, foreign_key: { to_table: :users }, null: true
    add_reference :games, :white_player, foreign_key: { to_table: :users }, null: true
  end
end 