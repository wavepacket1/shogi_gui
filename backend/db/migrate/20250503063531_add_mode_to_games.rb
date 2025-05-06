class AddModeToGames < ActiveRecord::Migration[7.0]
  def change
    # カラムが存在しない場合のみ追加
    unless column_exists?(:games, :mode)
      add_column :games, :mode, :string, default: 'play', null: false
    end
  end
end
