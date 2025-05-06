class AddPromotedToPieces < ActiveRecord::Migration[7.0]
  def change
    add_column :pieces, :promoted, :boolean
  end
end
