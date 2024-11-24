class CreatePieces < ActiveRecord::Migration[7.0]
  def change
    create_table :pieces do |t|
      t.references :board, null: false, foreign_key: true
      t.integer :position_x
      t.integer :position_y
      t.string :type

      t.timestamps
    end
  end
end
