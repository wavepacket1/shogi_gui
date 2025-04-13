# モード切替機能 API仕様書

## 1. エンドポイント一覧

### 1.1 ゲームモード関連

#### ゲームモードの変更
```yaml
POST /api/v1/games/{id}/mode
概要: ゲームのモードを変更する
パラメータ:
  - id: ゲームID (path)
  - mode: 変更後のモード (body)
    - play: 対局モード
    - edit: 編集モード
    - study: 検討モード
レスポンス:
  200:
    description: モード変更成功
    content:
      application/json:
        schema:
          type: object
          properties:
            game_id: integer
            mode: string
            status: string
            updated_at: string
  400:
    description: 不正なリクエスト
  404:
    description: ゲームが見つからない
```

### 1.2 編集モード関連

#### 局面の保存
```yaml
POST /api/v1/games/{id}/positions
概要: 編集モードで作成した局面を保存する
パラメータ:
  - id: ゲームID (path)
  - sfen: 局面のSFEN表記 (body)
  - active_player: 手番 (body)
  - comment: コメント (body, optional)
レスポンス:
  200:
    description: 保存成功
    content:
      application/json:
        schema:
          type: object
          properties:
            position_id: integer
            sfen: string
            created_at: string
```

#### 局面の読み込み
```yaml
GET /api/v1/games/{id}/positions/{position_id}
概要: 保存された局面を読み込む
パラメータ:
  - id: ゲームID (path)
  - position_id: 局面ID (path)
レスポンス:
  200:
    description: 読み込み成功
    content:
      application/json:
        schema:
          type: object
          properties:
            position_id: integer
            sfen: string
            active_player: string
            comment: string
```

### 1.3 検討モード関連

#### コメントの追加/編集
```yaml
POST /api/v1/games/{id}/moves/{move_number}/comments
概要: 指し手にコメントを追加/編集する
パラメータ:
  - id: ゲームID (path)
  - move_number: 手数 (path)
  - comment: コメント内容 (body)
  - branch: 分岐名 (body, optional)
レスポンス:
  200:
    description: コメント保存成功
    content:
      application/json:
        schema:
          type: object
          properties:
            comment_id: integer
            content: string
            updated_at: string
```

## 2. データ構造

### 2.1 ゲームモード

```typescript
enum GameMode {
  PLAY = 'play',
  EDIT = 'edit',
  STUDY = 'study'
}

interface GameModeUpdate {
  mode: GameMode;
  metadata?: {
    preserved_state?: string;  // 前のモードの状態を保存
    transition_reason?: string;  // モード変更の理由
  };
}
```

### 2.2 局面データ

```typescript
interface Position {
  id: number;
  game_id: number;
  sfen: string;
  active_player: 'black' | 'white';
  mode: GameMode;
  metadata: {
    created_at: string;
    updated_at: string;
    comment?: string;
    tags?: string[];
  };
}
```

### 2.3 コメントデータ

```typescript
interface MoveComment {
  id: number;
  game_id: number;
  move_number: number;
  branch: string;
  content: string;
  author_id?: number;
  created_at: string;
  updated_at: string;
}
```

## 3. エラー定義

### 3.1 エラーレスポンス

```typescript
interface ApiError {
  code: string;
  message: string;
  details?: {
    field?: string;
    reason?: string;
  };
}
```

### 3.2 エラーコード

```yaml
INVALID_MODE_TRANSITION:
  code: '400'
  message: '無効なモード遷移です'

UNSAVED_CHANGES:
  code: '409'
  message: '保存されていない変更があります'

INVALID_POSITION:
  code: '400'
  message: '不正な局面です'

MODE_NOT_SUPPORTED:
  code: '405'
  message: '現在のモードではサポートされていない操作です'
```

## 4. 認証・認可

### 4.1 必要な権限

- 対局モード: 対局参加者のみ
- 編集モード: 管理者権限または対局作成者
- 検討モード: 閲覧権限を持つユーザー

### 4.2 権限チェック

```yaml
ヘッダー要件:
  Authorization: Bearer <token>
  
権限エラーレスポンス:
  401:
    description: 認証が必要です
  403:
    description: 権限がありません
```

## 5. レート制限

```yaml
制限:
  - モード切替: 10回/分
  - 局面保存: 30回/分
  - コメント追加: 60回/分

ヘッダー:
  X-RateLimit-Limit: 制限値
  X-RateLimit-Remaining: 残り回数
  X-RateLimit-Reset: リセット時刻
```

## 6. バッチ処理

### 6.1 定期実行

```yaml
- 未使用の保存局面の削除: 毎日深夜
- 編集モードの自動保存: 5分ごと
- 長時間放置された編集セッションの終了: 1時間ごと
```

## 7. WebSocket通知

### 7.1 イベント定義

```yaml
mode_changed:
  type: モード変更通知
  data:
    game_id: ゲームID
    new_mode: 新しいモード
    changed_by: 変更したユーザーID

position_updated:
  type: 局面更新通知
  data:
    game_id: ゲームID
    position_id: 局面ID
    sfen: 新しい局面

comment_added:
  type: コメント追加通知
  data:
    game_id: ゲームID
    move_number: 手数
    comment_id: コメントID
```

## 8. キャッシュ戦略

### 8.1 キャッシュ対象

```yaml
- 頻繁にアクセスされる局面
- コメント一覧
- ユーザーの権限情報

キャッシュ設定:
  Cache-Control: max-age=3600
  ETag: "バージョン識別子"
```

## 9. データベースインデックス

```sql
-- games テーブル
CREATE INDEX idx_games_mode ON games(mode);
CREATE INDEX idx_games_status ON games(status);

-- positions テーブル
CREATE INDEX idx_positions_game_id ON positions(game_id);
CREATE INDEX idx_positions_sfen ON positions(sfen);

-- comments テーブル
CREATE INDEX idx_comments_game_move ON comments(game_id, move_number);
CREATE INDEX idx_comments_branch ON comments(branch);
```