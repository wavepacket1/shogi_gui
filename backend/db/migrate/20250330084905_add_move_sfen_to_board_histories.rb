class AddMoveSfenToBoardHistories < ActiveRecord::Migration[7.0]
  def change
    add_column :board_histories, :move_sfen, :string
  end
end
