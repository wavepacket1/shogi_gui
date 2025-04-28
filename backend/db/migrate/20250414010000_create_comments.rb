class CreateComments < ActiveRecord::Migration[7.0]
  def change
    create_table :comments do |t|
      t.references :board_history, null: false, foreign_key: true, index: { name: 'idx_comments_board_history_id' }
      t.text :content, null: false
      t.timestamps
    end
    add_index :comments, :board_history_id, name: 'idx_comments_board_history'
  end
end 