class AddResignInfoToGames < ActiveRecord::Migration[7.0]
  def change
    add_column :games, :winner, :string
    add_column :games, :ended_at, :datetime
  end
end
