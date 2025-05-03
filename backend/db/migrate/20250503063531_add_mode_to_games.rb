class AddModeToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :mode, :string, default: 'play', null: false
  end
end
