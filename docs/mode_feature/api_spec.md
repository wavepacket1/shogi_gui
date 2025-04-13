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
  preserved_state?: string;  // 前のモードの状態を保存
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
  };
}
```

## 3. エラー定義

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

## 8. キャッシュ戦略

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

## 待った機能 API

### 待った要求の送信

```
POST /api/v1/games/{gameId}/take-back-requests
```

#### リクエスト
```json
{
  "moveNumber": 123  // 取り消したい手の番号
}
```

#### レスポンス
```json
{
  "requestId": "uuid-xxx",
  "status": "pending",
  "requestedAt": "2025-04-13T10:00:00Z",
  "timeoutAt": "2025-04-13T10:00:30Z"
}
```

### 待った要求への応答

```
PUT /api/v1/games/{gameId}/take-back-requests/{requestId}
```

#### リクエスト
```json
{
  "response": "accept" | "reject"
}
```

#### レスポンス
```json
{
  "requestId": "uuid-xxx",
  "status": "accepted" | "rejected",
  "respondedAt": "2025-04-13T10:00:15Z"
}
```

### 待った履歴の取得

```
GET /api/v1/games/{gameId}/take-back-history
```

#### レスポンス
```json
{
  "takeBackHistory": [
    {
      "requestId": "uuid-xxx",
      "moveNumber": 123,
      "requesterId": "user-id",
      "status": "accepted",
      "requestedAt": "2025-04-13T10:00:00Z",
      "respondedAt": "2025-04-13T10:00:15Z"
    }
  ],
  "remainingTakeBacks": 2  // 残りの待った回数
}
```

### エラーレスポンス
- 400 Bad Request: 不正なリクエスト
  - 直前の手以外を指定した場合
  - 残り回数が0の場合
- 403 Forbidden: 権限エラー
  - 自分の手番でない場合
  - 待った機能が無効な場合
- 404 Not Found: 指定されたゲームまたはリクエストが存在しない
- 409 Conflict: 既に他の待った要求が処理中

### 待った要求を送信

```
POST /api/games/{gameId}/takeback
```

#### リクエスト
```json
{
  "moveNumber": number  // 取り消したい手の番号
}
```

#### レスポンス
- 成功時 (200 OK)
```json
{
  "requestId": string,
  "timeoutAt": string,
  "remainingTakeBacks": number
}
```

### 待った要求に応答

```
PUT /api/games/{gameId}/takeback/{requestId}
```

#### リクエスト
```json
{
  "accepted": boolean
}
```

#### レスポンス
- 成功時 (200 OK)
```json
{
  "success": true,
  "boardState": {
    // 更新された盤面情報
  }
}
```

### WebSocket Events

#### 待った要求通知
```json
{
  "type": "TAKEBACK_REQUESTED",
  "data": {
    "requestId": string,
    "moveNumber": number,
    "requestedBy": string,
    "timeoutAt": string
  }
}
```

#### 待った応答通知
```json
{
  "type": "TAKEBACK_RESPONDED",
  "data": {
    "requestId": string,
    "accepted": boolean,
    "boardState": object // accepted=trueの場合のみ
  }
}
```

### エラーレスポンス
- 400 Bad Request: 無効な手番号
- 403 Forbidden: 待った権限なし
- 404 Not Found: 指定された対局またはリクエストが存在しない
- 409 Conflict: 既に待った要求中
- 410 Gone: 待った要求がタイムアウト