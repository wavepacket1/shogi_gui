class AddPlayerReferencesToGames < ActiveRecord::Migration[7.0]
  def change
    # カラムが存在しない場合のみ追加
    unless column_exists?(:games, :black_player_id)
      add_reference :games, :black_player, foreign_key: { to_table: :users }, null: true
    end
    
    unless column_exists?(:games, :white_player_id)
      add_reference :games, :white_player, foreign_key: { to_table: :users }, null: true
    end
  end
end 