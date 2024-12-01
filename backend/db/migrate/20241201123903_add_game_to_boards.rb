class AddGameToBoards < ActiveRecord::Migration[7.0]
  def up
    # まず、game_idカラムをNULL許可で追加
    add_reference :boards, :game, foreign_key: true, null: true

    # 既存のboardsレコードにデフォルトのgameを設定
    default_game = Game.first || Game.create!(
      name: 'Default Game', 
      active_player: 'b',
      status: 'active'
    )

    # game_idがNULLのboardsレコードを更新
    Board.reset_column_information
    Board.where(game_id: nil).update_all(game_id: default_game.id)

    change_column_null :boards, :game_id, false
  end

  def down
    # マイグレーションをロールバックする際にgame_idカラムを削除
    remove_reference :boards, :game, foreign_key: true
  end
end
