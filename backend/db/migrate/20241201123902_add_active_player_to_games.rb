class AddActivePlayerToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :active_player, :string, null: false, default: 'b'
  end
end
