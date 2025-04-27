# モード切替機能 データベース設計書

## 1. テーブル定義

### 1.1 既存テーブルの変更

```ruby
class AddModeAndPreservedStateToGames < ActiveRecord::Migration[6.1]
  def change
    add_column :games, :mode, :string, null: false, default: 'play'
    add_column :games, :preserved_state, :text
  end
end
```

```ruby
class AddEditedFieldsToBoardHistories < ActiveRecord::Migration[6.1]
  def change
    # is_edited: 編集モードでユーザーが手動で局面を編集したかを示すフラグ
    add_column :board_histories, :is_edited, :boolean, default: false
    # edited_at: 手動編集が行われた日時を保存
    add_column :board_histories, :edited_at, :datetime
  end
end
```

## 2. データ型定義

### 2.1 列挙型

```ruby
class AddGameModeEnum < ActiveRecord::Migration[6.1]
  def change
    add_column :games, :mode, :string, null: false, default: 'play'
  end
end
```

## 3. インデックスとパフォーマンス

### 3.1 推奨インデックス

```ruby
class AddIndexesForModeFeature < ActiveRecord::Migration[6.1]
  def change
    add_index :games, :mode, name: 'idx_games_mode'
  end
end
```

## 4. データ整合性

### 4.1 制約

```ruby
class AddModeTransitionConstraint < ActiveRecord::Migration[6.1]
  def change
    add_check_constraint :games, "mode IN ('play','edit','study')", name: 'check_games_mode'
  end
end
```

## 5. ロールバック計画

```ruby
# 例：AddModeAndPreservedStateToGames の down
class AddModeAndPreservedStateToGames < ActiveRecord::Migration[6.1]
  def down
    remove_column :games, :preserved_state
    remove_column :games, :mode
  end
end
```