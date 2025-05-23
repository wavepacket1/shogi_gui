class AddCustomPositionToBoards < ActiveRecord::Migration[7.0]
  def change
    add_column :boards, :custom_position, :boolean, default: false
    add_index :boards, :custom_position
  end
end
