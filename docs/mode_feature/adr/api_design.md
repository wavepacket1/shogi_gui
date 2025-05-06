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


## 2. エラー定義

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

### 2.2 エラーコード

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