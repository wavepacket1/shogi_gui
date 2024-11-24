class AddOwnerToPieces < ActiveRecord::Migration[7.0]
  def change
    add_column :pieces, :owner, :string
  end
end
