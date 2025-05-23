# データベース設計仕様

## 1. テーブル設計

### 1.1 Gamesテーブル拡張
既存のGamesテーブルに対局終了関連のカラムを追加します。

```ruby
class AddResignInfoToGames < ActiveRecord::Migration[7.0]
  def change
    # 既存のstatusカラムに制約を追加
    change_column :games, :status, :string, null: false, default: 'active'
    
    # 新規カラムの追加
    add_column :games, :winner, :string  # black, white
    add_column :games, :ended_at, :datetime
    
    # インデックスの追加
    add_index :games, :status
    
    # 制約の追加
    add_check_constraint :games, "status IN ('active', 'finished')", name: 'check_valid_status'
    add_check_constraint :games, "winner IN ('black', 'white')", name: 'check_valid_winner'
  end
end
```

### 1.2 プレイヤー参照カラムの追加
```ruby
class AddPlayerReferencesToGames < ActiveRecord::Migration[7.0]
  def change
    # プレイヤー参照カラムの追加
    add_reference :games, :black_player, foreign_key: { to_table: :users }
    add_reference :games, :white_player, foreign_key: { to_table: :users }
  end
end
```

## 2. モデル定義

### 2.1 Gameモデル
```ruby
class Game < ApplicationRecord
  # リレーション
  belongs_to :black_player, class_name: 'User'
  belongs_to :white_player, class_name: 'User'
  has_many :board_histories, dependent: :destroy
  has_one :current_board_state, -> { 
    where(branch: 'main').order(move_number: :desc) 
  }, class_name: 'BoardHistory'

  # 定数定義
  STATUSES = %w[active finished].freeze
  PLAYERS = %w[black white].freeze

  # バリデーション
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :winner, inclusion: { in: PLAYERS }, allow_nil: true
  validates :black_player, presence: true
  validates :white_player, presence: true
  validate :winner_must_be_present_if_game_ended
  validate :players_must_be_different

  # スコープ
  scope :active, -> { where(status: 'active') }
  scope :finished, -> { where(status: 'finished') }

  # 投了処理メソッド
  def resign!(user:)
    raise GameError, '既に対局は終了しています' unless active?
    
    # プレイヤーの手番確認
    player_color = player_color(user)
    raise GameError, 'この対局のプレイヤーではありません' unless player_color
    
    # 投了した側の反対の手番を勝者とする
    winning_player = player_color == 'black' ? 'white' : 'black'

    update!(
      status: 'finished',
      winner: winning_player,
      ended_at: Time.current
    )
  end

  # ゲーム状態確認メソッド
  def active?
    status == 'active'
  end

  def finished?
    !active?
  end

  # プレイヤー確認メソッド
  def valid_player?(player)
    player.in?(%w[black white])
  end

  # プレイヤー関連メソッド
  def player_by_color(color)
    color == 'black' ? black_player : white_player
  end

  def player_color(user)
    return 'black' if user.id == black_player_id
    return 'white' if user.id == white_player_id
    nil
  end

  private

  def winner_must_be_present_if_game_ended
    if status != 'active'
      errors.add(:winner, "must be present") if winner.nil?
      errors.add(:ended_at, "must be present") if ended_at.nil?
    end
  end

  def players_must_be_different
    if black_player_id == white_player_id
      errors.add(:base, "同じプレイヤーが両方の手番を担当することはできません")
    end
  end
end
```

## 3. データ整合性

### 3.1 トランザクション管理
- 対局終了処理は必ずトランザクション内で実行
- 関連する全てのレコード更新を保証

### 3.2 データ検証
- モデルバリデーションによる整合性チェック
- DBレベルでの制約による整合性保証
- 手番と投了プレイヤーの整合性確認 