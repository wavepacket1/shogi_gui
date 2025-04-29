# モード切替機能 データベース設計仕様書

## 1. テーブル定義

### 1.1 既存テーブルの変更

#### games テーブル

```sql
-- モード関連カラムの追加
ALTER TABLE games
ADD COLUMN mode varchar(10) NOT NULL DEFAULT 'play',
ADD COLUMN preserved_state text;

COMMENT ON COLUMN games.mode IS 'current game mode: play, edit, or study';
COMMENT ON COLUMN games.preserved_state IS 'preserved state data when switching modes (JSON format)';

-- 待った機能の設定を追加
ALTER TABLE games ADD COLUMN take_back_enabled boolean NOT NULL DEFAULT true;
ALTER TABLE games ADD COLUMN max_take_backs integer NOT NULL DEFAULT 3;
ALTER TABLE games ADD COLUMN take_back_timeout integer NOT NULL DEFAULT 30;
```

#### board_histories テーブル

```sql
-- 編集モード用のカラム追加
ALTER TABLE board_histories
ADD COLUMN is_edited boolean DEFAULT false,
ADD COLUMN edited_at timestamp with time zone;

COMMENT ON COLUMN board_histories.is_edited IS 'flag indicating if position was manually edited';
COMMENT ON COLUMN board_histories.edited_at IS 'timestamp when position was edited';
```

## 2. データ型定義

### 2.1 列挙型

```sql
-- ゲームモード
CREATE TYPE game_mode AS ENUM ('play', 'edit', 'study');

COMMENT ON TYPE game_mode IS 'Valid game modes';

-- 待った要求の状態
CREATE TYPE take_back_status AS ENUM ('pending', 'accepted', 'rejected', 'timeout');
```

## 3. インデックスとパフォーマンス

### 3.1 推奨インデックス

```sql
-- モード検索用のインデックス
CREATE INDEX idx_games_mode ON games(mode);

-- 待った要求のインデックス
CREATE INDEX idx_take_back_game ON take_back_requests(game_id);
CREATE INDEX idx_take_back_status ON take_back_requests(status);

-- 待った履歴のインデックス
CREATE INDEX idx_take_back_history_game ON take_back_history(game_id);
CREATE INDEX idx_take_back_history_request ON take_back_history(request_id);
```

## 4. データ整合性

### 4.1 制約

```sql
-- モード切替の制約
ALTER TABLE games
ADD CONSTRAINT valid_mode_transition
CHECK (mode IN ('play', 'edit', 'study'));

-- 待った要求の制約
ALTER TABLE take_back_requests
ADD CONSTRAINT valid_move_number CHECK (move_number > 0);

-- 待った履歴の制約
ALTER TABLE take_back_history
ADD CONSTRAINT valid_move_number CHECK (move_number > 0);
```

## 5. ロールバック計画

```sql
-- ロールバック用のSQLスクリプト
BEGIN;

-- 追加したカラムの削除
ALTER TABLE board_histories
    DROP COLUMN IF EXISTS is_edited,
    DROP COLUMN IF EXISTS edited_at;

ALTER TABLE games
    DROP COLUMN IF EXISTS mode,
    DROP COLUMN IF EXISTS preserved_state,
    DROP COLUMN IF EXISTS take_back_enabled,
    DROP COLUMN IF EXISTS max_take_backs,
    DROP COLUMN IF EXISTS take_back_timeout;

-- 列挙型の削除
DROP TYPE IF EXISTS game_mode;
DROP TYPE IF EXISTS take_back_status;

-- インデックスの削除
DROP INDEX IF EXISTS idx_games_mode;
DROP INDEX IF EXISTS idx_take_back_game;
DROP INDEX IF EXISTS idx_take_back_status;
DROP INDEX IF EXISTS idx_take_back_history_game;
DROP INDEX IF EXISTS idx_take_back_history_request;

-- テーブルの削除
DROP TABLE IF EXISTS take_back_requests;
DROP TABLE IF EXISTS take_back_history;

COMMIT;
```

## take_back_requests テーブル

待った要求を管理するテーブル

| カラム名 | 型 | NULL | デフォルト | 説明 |
|----------|-----|------|------------|------|
| id | uuid | NO | - | 主キー |
| game_id | bigint | NO | - | 対局ID（外部キー） |
| requester_id | bigint | NO | - | 要求者のユーザーID（外部キー） |
| move_number | integer | NO | - | 取り消したい手の番号 |
| status | enum | NO | 'pending' | 状態（pending/accepted/rejected/timeout） |
| requested_at | timestamp | NO | CURRENT_TIMESTAMP | 要求日時 |
| responded_at | timestamp | YES | NULL | 応答日時 |
| created_at | timestamp | NO | CURRENT_TIMESTAMP | 作成日時 |
| updated_at | timestamp | NO | CURRENT_TIMESTAMP | 更新日時 |

```sql
CREATE TABLE take_back_requests (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    game_id bigint NOT NULL REFERENCES games(id),
    requester_id bigint NOT NULL REFERENCES users(id),
    move_number integer NOT NULL,
    status take_back_status NOT NULL DEFAULT 'pending',
    requested_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    responded_at timestamp,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_move_number CHECK (move_number > 0)
);
```

## take_back_history テーブル

実行された待った操作の履歴を管理するテーブル

| カラム名 | 型 | NULL | デフォルト | 説明 |
|----------|-----|------|------------|------|
| id | uuid | NO | - | 主キー |
| request_id | uuid | NO | - | 対応する要求ID（外部キー） |
| game_id | bigint | NO | - | 対局ID（外部キー） |
| move_number | integer | NO | - | 取り消された手の番号 |
| previous_sfen | string | NO | - | 取り消し前のSFEN |
| current_sfen | string | NO | - | 取り消し後のSFEN |
| executed_at | timestamp | NO | CURRENT_TIMESTAMP | 実行日時 |
| created_at | timestamp | NO | CURRENT_TIMESTAMP | 作成日時 |

```sql
CREATE TABLE take_back_history (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    request_id uuid NOT NULL REFERENCES take_back_requests(id),
    game_id bigint NOT NULL REFERENCES games(id),
    move_number integer NOT NULL,
    previous_sfen text NOT NULL,
    current_sfen text NOT NULL,
    executed_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_move_number CHECK (move_number > 0)
);
```