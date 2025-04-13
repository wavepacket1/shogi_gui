# モード切替機能 データベース設計仕様書

## 1. テーブル定義

### 1.1 既存テーブルの変更

#### games テーブル

```sql
-- モード関連カラムの追加
ALTER TABLE games
ADD COLUMN mode varchar(10) NOT NULL DEFAULT 'play',
ADD COLUMN previous_mode varchar(10),
ADD COLUMN mode_metadata jsonb,
ADD COLUMN last_mode_change timestamp with time zone,
ADD CONSTRAINT valid_mode CHECK (mode IN ('play', 'edit', 'study'));

COMMENT ON COLUMN games.mode IS 'current game mode: play, edit, or study';
COMMENT ON COLUMN games.previous_mode IS 'previous game mode before current mode';
COMMENT ON COLUMN games.mode_metadata IS 'additional metadata for mode-specific features';
COMMENT ON COLUMN games.last_mode_change IS 'timestamp of last mode change';
```

#### board_histories テーブル

```sql
-- 編集モード・検討モード用のカラム追加
ALTER TABLE board_histories
ADD COLUMN editor_id integer REFERENCES users(id),
ADD COLUMN edit_comment text,
ADD COLUMN is_edited boolean DEFAULT false,
ADD COLUMN edited_at timestamp with time zone;

COMMENT ON COLUMN board_histories.editor_id IS 'user who edited this position';
COMMENT ON COLUMN board_histories.edit_comment IS 'comment about the edit';
COMMENT ON COLUMN board_histories.is_edited IS 'flag indicating if position was manually edited';
COMMENT ON COLUMN board_histories.edited_at IS 'timestamp when position was edited';
```

### 1.2 新規テーブル

#### position_comments テーブル

```sql
CREATE TABLE position_comments (
    id SERIAL PRIMARY KEY,
    game_id integer NOT NULL REFERENCES games(id),
    board_history_id integer NOT NULL REFERENCES board_histories(id),
    user_id integer NOT NULL REFERENCES users(id),
    content text NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    parent_comment_id integer REFERENCES position_comments(id),
    
    CONSTRAINT valid_content CHECK (length(content) > 0)
);

CREATE INDEX idx_position_comments_game ON position_comments(game_id);
CREATE INDEX idx_position_comments_board_history ON position_comments(board_history_id);
CREATE INDEX idx_position_comments_user ON position_comments(user_id);

COMMENT ON TABLE position_comments IS 'Comments on board positions in study mode';
```

#### edit_sessions テーブル

```sql
CREATE TABLE edit_sessions (
    id SERIAL PRIMARY KEY,
    game_id integer NOT NULL REFERENCES games(id),
    user_id integer NOT NULL REFERENCES users(id),
    started_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ended_at timestamp with time zone,
    initial_sfen text NOT NULL,
    current_sfen text NOT NULL,
    is_active boolean NOT NULL DEFAULT true,
    autosave_data jsonb,
    
    CONSTRAINT valid_session CHECK (ended_at IS NULL OR ended_at > started_at)
);

CREATE INDEX idx_edit_sessions_game ON edit_sessions(game_id);
CREATE INDEX idx_edit_sessions_user ON edit_sessions(user_id);
CREATE INDEX idx_edit_sessions_active ON edit_sessions(is_active);

COMMENT ON TABLE edit_sessions IS 'Active editing sessions in edit mode';
```

#### edit_history_entries テーブル

```sql
CREATE TABLE edit_history_entries (
    id SERIAL PRIMARY KEY,
    edit_session_id integer NOT NULL REFERENCES edit_sessions(id),
    action_type varchar(20) NOT NULL,
    piece_type varchar(10) NOT NULL,
    source_position varchar(4),
    target_position varchar(4),
    metadata jsonb,
    created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT valid_action_type CHECK (action_type IN 
        ('place', 'remove', 'move', 'promote', 'unpromote'))
);

CREATE INDEX idx_edit_history_entries_session ON edit_history_entries(edit_session_id);

COMMENT ON TABLE edit_history_entries IS 'History of edits made in edit mode';
```

## 2. データ型定義

### 2.1 列挙型

```sql
-- ゲームモード
CREATE TYPE game_mode AS ENUM ('play', 'edit', 'study');

-- 編集アクション
CREATE TYPE edit_action AS ENUM (
    'place',      -- 駒を配置
    'remove',     -- 駒を削除
    'move',       -- 駒を移動
    'promote',    -- 駒を成る
    'unpromote'   -- 駒を不成にする
);
```

### 2.2 複合型

```sql
-- 編集メタデータ
CREATE TYPE edit_metadata AS (
    timestamp timestamp with time zone,
    editor_id integer,
    comment text,
    undo_data jsonb
);

-- 局面メタデータ
CREATE TYPE position_metadata AS (
    created_by integer,
    created_at timestamp with time zone,
    last_modified_by integer,
    last_modified_at timestamp with time zone,
    comments_count integer,
    tags text[]
);
```

## 3. マイグレーション計画

### 3.1 実行順序

1. 列挙型の作成
2. games テーブルの拡張
3. board_histories テーブルの拡張
4. 新規テーブルの作成
5. インデックスの作成
6. 既存データの移行

### 3.2 ロールバック計画

```sql
-- ロールバック用のSQLスクリプト
BEGIN;

-- 新規テーブルの削除
DROP TABLE IF EXISTS edit_history_entries;
DROP TABLE IF EXISTS edit_sessions;
DROP TABLE IF EXISTS position_comments;

-- 追加したカラムの削除
ALTER TABLE board_histories
    DROP COLUMN IF EXISTS editor_id,
    DROP COLUMN IF EXISTS edit_comment,
    DROP COLUMN IF EXISTS is_edited,
    DROP COLUMN IF EXISTS edited_at;

ALTER TABLE games
    DROP COLUMN IF EXISTS mode,
    DROP COLUMN IF EXISTS previous_mode,
    DROP COLUMN IF EXISTS mode_metadata,
    DROP COLUMN IF EXISTS last_mode_change;

-- 列挙型の削除
DROP TYPE IF EXISTS edit_metadata;
DROP TYPE IF EXISTS position_metadata;
DROP TYPE IF EXISTS game_mode;
DROP TYPE IF EXISTS edit_action;

COMMIT;
```

## 4. インデックスとパフォーマンス

### 4.1 推奨インデックス

```sql
-- パフォーマンス重要なクエリ用のインデックス
CREATE INDEX idx_games_active_mode ON games(mode) WHERE status = 'active';
CREATE INDEX idx_board_histories_edited ON board_histories(game_id, is_edited);
CREATE INDEX idx_edit_sessions_recent ON edit_sessions(game_id, started_at DESC);
```

### 4.2 パーティショニング戦略

```sql
-- 編集履歴のパーティショニング（オプション）
CREATE TABLE edit_history_entries_partitioned (
    LIKE edit_history_entries INCLUDING ALL
) PARTITION BY RANGE (created_at);

-- 月次パーティションの作成
CREATE TABLE edit_history_entries_y2025m04 
    PARTITION OF edit_history_entries_partitioned
    FOR VALUES FROM ('2025-04-01') TO ('2025-05-01');
```

## 5. データ整合性

### 5.1 制約

```sql
-- モード切替の制約
ALTER TABLE games
ADD CONSTRAINT valid_mode_transition
CHECK (
    (mode = 'play' AND previous_mode IN (NULL, 'edit', 'study')) OR
    (mode = 'edit' AND previous_mode IN (NULL, 'play', 'study')) OR
    (mode = 'study' AND previous_mode IN (NULL, 'play', 'edit'))
);

-- 編集セッションの制約
ALTER TABLE edit_sessions
ADD CONSTRAINT single_active_session
UNIQUE (game_id, user_id) 
WHERE is_active = true;
```

### 5.2 トリガー

```sql
-- モード変更トリガー
CREATE FUNCTION log_mode_change() RETURNS trigger AS $$
BEGIN
    IF NEW.mode <> OLD.mode THEN
        NEW.last_mode_change = CURRENT_TIMESTAMP;
        NEW.previous_mode = OLD.mode;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER mode_change_trigger
    BEFORE UPDATE OF mode ON games
    FOR EACH ROW
    EXECUTE FUNCTION log_mode_change();
```

## 6. セキュリティ

### 6.1 権限設定

```sql
-- ロール別の権限設定
GRANT SELECT ON games TO player;
GRANT UPDATE (mode, mode_metadata) ON games TO player;
GRANT ALL ON edit_sessions TO editor;
GRANT SELECT, INSERT ON position_comments TO viewer;
```

### 6.2 行レベルセキュリティ

```sql
-- 編集セッションのRLS
ALTER TABLE edit_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY edit_session_access ON edit_sessions
    USING (user_id = current_user_id() OR 
           EXISTS (SELECT 1 FROM games g 
                  WHERE g.id = game_id AND g.creator_id = current_user_id()));
```

## 7. バックアップと復元

### 7.1 バックアップ戦略

```yaml
完全バックアップ: 毎日深夜
差分バックアップ: 4時間ごと
WALアーカイブ: 継続的

バックアップ対象:
  - games
  - board_histories
  - edit_sessions
  - edit_history_entries
  - position_comments
```

### 7.2 復元手順

```sql
-- リストア手順
BEGIN;
-- 1. ベーステーブルの復元
\copy games FROM 'backup/games.csv' WITH CSV HEADER;
-- 2. 関連テーブルの復元
\copy edit_sessions FROM 'backup/edit_sessions.csv' WITH CSV HEADER;
-- 3. インデックスの再構築
REINDEX TABLE games;
REINDEX TABLE edit_sessions;
COMMIT;
```