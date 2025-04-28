class AddModeToGames < ActiveRecord::Migration[7.0]
  def up
    add_column :games, :mode, :string, null: false, default: 'play'
    # 既存レコードにはデフォルト値が自動適用されるため、追加のデータ移行用スクリプトは不要です
  end

  def down
    remove_column :games, :mode
  end
end 