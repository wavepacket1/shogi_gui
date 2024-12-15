class RenameTypeColumnInPieces < ActiveRecord::Migration[7.0]
  def change
    rename_column :pieces, :type, :piece_type
  end
end
