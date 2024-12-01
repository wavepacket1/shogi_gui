
class AddActivePlayerToBoards < ActiveRecord::Migration[6.0]
  def change
    add_column :boards, :active_player, :string, default: 'b'
  end
end