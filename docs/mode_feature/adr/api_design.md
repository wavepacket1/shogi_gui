# モード切替機能 API設計書

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

### 1.2 検討モード関連

#### 1.2.1 コメント管理API

##### コメント一覧取得
```yaml
GET /api/v1/games/{game_id}/board_histories/{move_number}/comments
概要: 指定局面のコメント一覧を取得する
パラメータ:
  - game_id: ゲームID (path)
  - move_number: 手数 (path)
  - branch: 分岐名 (query, optional, default: main)
レスポンス:
  200:
    description: コメント一覧取得成功
    content:
      application/json:
        schema:
          type: array
          items:
            type: object
            properties:
              id: integer
              board_history_id: integer
              content: string
              created_at: string
              updated_at: string
  404:
    description: 局面が見つからない
```

##### コメント作成
```yaml
POST /api/v1/games/{game_id}/board_histories/{move_number}/comments
概要: 指定局面にコメントを作成する
パラメータ:
  - game_id: ゲームID (path)
  - move_number: 手数 (path)
  - branch: 分岐名 (query, optional, default: main)
  - comment: コメント内容 (body)
    - content: string (required, max: 1000文字)
リクエスト例:
  {
    "comment": {
      "content": "この局面では角交換が有力です。"
    }
  }
レスポンス:
  201:
    description: コメント作成成功
    content:
      application/json:
        schema:
          type: object
          properties:
            comment_id: integer
            content: string
            updated_at: string
  400:
    description: 不正なリクエスト（文字数超過等）
  404:
    description: 局面が見つからない
  422:
    description: バリデーションエラー
```

##### コメント更新
```yaml
PUT /api/v1/games/{game_id}/board_histories/{move_number}/comments/{comment_id}
概要: 指定コメントを更新する
パラメータ:
  - game_id: ゲームID (path)
  - move_number: 手数 (path)
  - comment_id: コメントID (path)
  - branch: 分岐名 (query, optional, default: main)
  - comment: コメント内容 (body)
    - content: string (required, max: 1000文字)
リクエスト例:
  {
    "comment": {
      "content": "修正：この局面では▲角交換が最善です。"
    }
  }
レスポンス:
  200:
    description: コメント更新成功
    content:
      application/json:
        schema:
          type: object
          properties:
            comment_id: integer
            content: string
            updated_at: string
  400:
    description: 不正なリクエスト
  404:
    description: コメントが見つからない
  422:
    description: バリデーションエラー
```

##### コメント削除
```yaml
DELETE /api/v1/games/{game_id}/board_histories/{move_number}/comments/{comment_id}
概要: 指定コメントを削除する
パラメータ:
  - game_id: ゲームID (path)
  - move_number: 手数 (path)
  - comment_id: コメントID (path)
  - branch: 分岐名 (query, optional, default: main)
レスポンス:
  200:
    description: コメント削除成功
    content:
      application/json:
        schema:
          type: object
          properties:
            message: string
  404:
    description: コメントが見つからない
```

#### 1.2.2 分岐管理API

##### 分岐一覧取得
```yaml
GET /api/v1/games/{game_id}/branches
概要: ゲームの全分岐一覧を取得する
パラメータ:
  - game_id: ゲームID (path)
レスポンス:
  200:
    description: 分岐一覧取得成功
    content:
      application/json:
        schema:
          type: object
          properties:
            branches: 
              type: array
              items:
                type: string
レスポンス例:
  {
    "branches": ["main", "variation-1", "variation-2"]
  }
```

##### 分岐作成
```yaml
POST /api/v1/games/{game_id}/board_histories/{move_number}/branches
概要: 指定局面から新しい分岐を作成する
パラメータ:
  - game_id: ゲームID (path)
  - move_number: 分岐開始手数 (path)
  - branch_name: 新しい分岐名 (body, optional)
  - source_branch: 分岐元の分岐名 (body, optional, default: main)
リクエスト例:
  {
    "branch_name": "variation-1",
    "source_branch": "main"
  }
レスポンス:
  201:
    description: 分岐作成成功
    content:
      application/json:
        schema:
          type: object
          properties:
            branch_name: string
            created_at: string
            move_number: integer
  400:
    description: 不正なリクエスト（分岐名重複等）
  404:
    description: 局面が見つからない
```

##### 分岐削除
```yaml
DELETE /api/v1/games/{game_id}/branches/{branch_name}
概要: 指定分岐とその全履歴を削除する
パラメータ:
  - game_id: ゲームID (path)
  - branch_name: 削除する分岐名 (path)
制約:
  - main分岐は削除不可
  - 分岐に含まれる全board_historiesとcommentsを連動削除
レスポンス:
  200:
    description: 分岐削除成功
    content:
      application/json:
        schema:
          type: object
          properties:
            message: string
            deleted_histories: integer
            deleted_comments: integer
  400:
    description: main分岐削除試行等の不正リクエスト
  404:
    description: 分岐が見つからない
```

#### 1.2.3 手順管理API

##### 手順削除（指定手順以降）
```yaml
DELETE /api/v1/games/{game_id}/board_histories/{move_number}/after
概要: 指定手順以降の全手順とコメントを削除する
パラメータ:
  - game_id: ゲームID (path)
  - move_number: 削除開始手数 (path)
  - branch: 対象分岐名 (query, optional, default: main)
制約:
  - move_number=0（初期局面）は削除不可
  - 指定手順以降の全board_historiesとcommentsを連動削除
レスポンス:
  200:
    description: 手順削除成功
    content:
      application/json:
        schema:
          type: object
          properties:
            message: string
            deleted_histories: integer
            deleted_comments: integer
  400:
    description: 初期局面削除試行等の不正リクエスト
  404:
    description: 手順が見つからない
```

#### 1.2.4 手順履歴API（既存拡張）

##### 履歴一覧取得（分岐対応）
```yaml
GET /api/v1/games/{game_id}/board_histories
概要: 指定ゲームの手順履歴一覧を取得する
パラメータ:
  - game_id: ゲームID (path)
  - branch: 分岐名 (query, optional, default: main)
  - with_comments: コメント含む (query, optional, default: false)
レスポンス:
  200:
    description: 履歴一覧取得成功
    content:
      application/json:
        schema:
          type: array
          items:
            type: object
            properties:
              id: integer
              move_number: integer
              sfen: string
              move_sfen: string
              notation: string
              branch: string
              created_at: string
              comments: array (with_comments=trueの場合のみ)
```

## 2. データ形式

### 2.1 Comment
```typescript
interface Comment {
  id: number;
  board_history_id: number;
  content: string;
  created_at: string;
  updated_at: string;
}
```

### 2.2 BoardHistory（分岐対応）
```typescript
interface BoardHistory {
  id: number;
  game_id: number;
  move_number: number;
  branch: string;
  sfen: string;
  move_sfen?: string;
  notation: string;
  created_at: string;
  updated_at: string;
  comments?: Comment[];
}
```

### 2.3 Branch
```typescript
interface Branch {
  name: string;
  created_at: string;
  move_count: number;
  comment_count: number;
}
```

## 3. エラー定義

### 3.1 基本エラー形式
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

### 3.2 検討モード固有エラーコード

#### コメント関連
```yaml
COMMENT_TOO_LONG:
  code: '400'
  message: 'コメントは1000文字以内で入力してください'

COMMENT_NOT_FOUND:
  code: '404'
  message: 'コメントが見つかりません'

COMMENT_SAVE_FAILED:
  code: '500'
  message: 'コメントの保存に失敗しました'
```

#### 分岐管理関連
```yaml
BRANCH_NAME_DUPLICATE:
  code: '400'
  message: '同じ名前の分岐が既に存在します'

BRANCH_NAME_INVALID:
  code: '400'
  message: '分岐名は英数字と-_のみ使用できます'

MAIN_BRANCH_DELETE:
  code: '400'
  message: 'main分岐は削除できません'

BRANCH_NOT_FOUND:
  code: '404'
  message: '指定された分岐が見つかりません'
```

#### 手順削除関連
```yaml
INITIAL_MOVE_DELETE:
  code: '400'
  message: '初期局面は削除できません'

MOVE_DELETE_FAILED:
  code: '500'
  message: '手順の削除に失敗しました'
```

#### 合法手チェック関連
```yaml
ILLEGAL_MOVE:
  code: '400'
  message: '不正な手です。将棋のルールに従って指してください'

PIECE_CANNOT_MOVE:
  code: '400'
  message: 'その駒はその位置に移動できません'

KING_IN_CHECK:
  code: '400'
  message: '王手を回避する必要があります'

INVALID_DROP:
  code: '400'
  message: 'その位置には駒を打てません'

NIFU_VIOLATION:
  code: '400'
  message: '二歩は禁止されています'
```

### 3.3 汎用エラーコード
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

NETWORK_ERROR:
  code: '503'
  message: '通信エラーが発生しました。接続を確認してください'
```

## 4. バリデーション仕様

### 4.1 コメント
- content: required, string, max: 1000文字
- HTMLタグのエスケープ処理
- XSS対策（サニタイズ）

### 4.2 分岐名
- 英数字と-_のみ許可
- 最大20文字
- 重複チェック
- 予約語チェック（main, system等）

### 4.3 手数
- 0以上の整数
- ゲーム内の最大手数以下
- 存在する手数のみ許可

### 4.4 指し手（検討モード）
- 移動手: 移動元・移動先の座標が盤面内
- 駒打ち: 打てる駒が持ち駒に存在
- 合法手判定: 
  - 移動可能範囲のチェック
  - 王手回避のチェック
  - 二歩・行き場のない駒のチェック
- 以下は緩和:
  - 千日手判定（同一局面の繰り返し許可）
  - 詰み判定（詰みでも継続可能）
  - 時間制限（無制限）

## 5. 認証・権限

### 5.1 基本認証
- 全エンドポイントで認証必須
- JWTトークンによる認証

### 5.2 権限制御
- 自分が作成したゲームのみ編集可能
- 読み取り専用ユーザーは GET のみ許可
- 管理者は全ゲームの操作が可能

## 6. レート制限

### 6.1 コメント操作
- コメント作成: 10回/分
- コメント更新: 20回/分
- コメント削除: 5回/分

### 6.2 分岐操作
- 分岐作成: 5回/分
- 分岐削除: 2回/分

### 6.3 手順削除
- 手順削除: 3回/分

## 7. パフォーマンス要件

### 7.1 応答時間
- コメント操作: 1秒以内
- 分岐操作: 2秒以内
- 履歴取得: 3秒以内（100手まで）

### 7.2 同時接続
- 最大100ユーザー/ゲーム
- コメント同時編集時の競合解決

## 8. セキュリティ

### 8.1 入力値検証
- 全パラメータの型・範囲チェック
- SQLインジェクション対策
- XSS対策（コメント内容のサニタイズ）

### 8.2 アクセス制御
- CORS設定
- CSRFトークン
- API使用量制限

## 9. ログ・監視

### 9.1 アクセスログ
- 全API呼び出しのログ記録
- エラー発生時の詳細ログ
- パフォーマンス監視

### 9.2 業務ログ
- コメント作成・更新・削除のログ
- 分岐作成・削除のログ
- 異常操作の検知・アラート

## 10. 実装上の注意点

### 10.1 既存API活用
- CommentsController: 完全実装済み、そのまま利用
- BoardHistoriesController: 分岐管理機能拡張が必要
- 新規API: 分岐削除、手順削除のみ

### 10.2 データベース制約
- 外部キー制約による整合性確保
- インデックス設定によるパフォーマンス最適化
- カスケード削除設定

### 10.3 トランザクション
- 分岐削除時の複数テーブル操作
- 手順削除時の関連データ削除
- ロールバック機能