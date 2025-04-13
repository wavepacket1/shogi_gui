# 将棋GUI 手の履歴機能 - API仕様書

## 概要

本ドキュメントでは、将棋GUIの手の履歴機能に関連するAPIの仕様を定義します。
これらのAPIは、ゲームの進行に伴う局面の保存、履歴の取得、過去の局面への移動などの機能を提供します。

## API一覧

### 1. 局面履歴の取得

#### リクエスト

```
GET /api/v1/games/:game_id/board_histories
```

**URLパラメータ**:
- `game_id` (必須) - ゲームのID

**クエリパラメータ**:
- `branch` (任意) - 分岐名。指定がない場合は「main」

#### レスポンス

**成功時 (200 OK)**:
```json
[
  {
    "id": 1,
    "game_id": 123,
    "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0",
    "move_number": 0,
    "branch": "main",
    "created_at": "2023-01-01T12:00:00Z",
    "updated_at": "2023-01-01T12:00:00Z",
    "notation": null
  },
  {
    "id": 2,
    "game_id": 123,
    "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1",
    "move_number": 1,
    "branch": "main",
    "created_at": "2023-01-01T12:01:00Z",
    "updated_at": "2023-01-01T12:01:00Z",
    "notation": "▲７六歩"
  }
]
```

**エラー時 (404 Not Found)**:
```json
{
  "error": "Game not found",
  "status": 404
}
```

#### OpenAPI Specification

```yaml
/api/v1/games/{game_id}/board_histories:
  get:
    summary: 局面履歴の取得
    tags:
      - BoardHistories
    parameters:
      - name: game_id
        in: path
        required: true
        schema:
          type: integer
        description: ゲームID
      - name: branch
        in: query
        required: false
        schema:
          type: string
        description: 分岐名（デフォルト: main）
    responses:
      '200':
        description: 履歴取得成功
        content:
          application/json:
            schema:
              type: array
              items:
                type: object
                properties:
                  id:
                    type: integer
                  game_id:
                    type: integer
                  sfen:
                    type: string
                  move_number:
                    type: integer
                  branch:
                    type: string
                  created_at:
                    type: string
                    format: date-time
                  updated_at:
                    type: string
                    format: date-time
                  notation:
                    type: string
                    nullable: true
      '404':
        description: ゲームが見つからない
        content:
          application/json:
            schema:
              type: object
              properties:
                error:
                  type: string
                status:
                  type: integer
```

### 2. 分岐リストの取得

#### リクエスト

```
GET /api/v1/games/:game_id/board_histories/branches
```

**URLパラメータ**:
- `game_id` (必須) - ゲームのID

#### レスポンス

**成功時 (200 OK)**:
```json
{
  "branches": ["main", "main_1", "main_2"]
}
```

**エラー時 (404 Not Found)**:
```json
{
  "error": "Game not found",
  "status": 404
}
```

#### OpenAPI Specification

```yaml
/api/v1/games/{game_id}/board_histories/branches:
  get:
    summary: 分岐リストの取得
    tags:
      - BoardHistories
    parameters:
      - name: game_id
        in: path
        required: true
        schema:
          type: integer
        description: ゲームID
    responses:
      '200':
        description: 分岐リスト取得成功
        content:
          application/json:
            schema:
              type: object
              properties:
                branches:
                  type: array
                  items:
                    type: string
      '404':
        description: ゲームが見つからない
        content:
          application/json:
            schema:
              type: object
              properties:
                error:
                  type: string
                status:
                  type: integer
```

### 3. 指定した手数の局面に移動

#### リクエスト

```
POST /api/v1/games/:game_id/navigate_to/:move_number
```

**URLパラメータ**:
- `game_id` (必須) - ゲームのID
- `move_number` (必須) - 移動先の手数

**クエリパラメータ**:
- `branch` (任意) - 分岐名。指定がない場合は「main」

#### レスポンス

**成功時 (200 OK)**:
```json
{
  "game_id": 123,
  "board_id": 456,
  "move_number": 5,
  "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1"
}
```

**エラー時 (404 Not Found)**:
```json
{
  "error": "Move number not found in branch",
  "status": 404
}
```

#### OpenAPI Specification

```yaml
/api/v1/games/{game_id}/navigate_to/{move_number}:
  post:
    summary: 指定した手数の局面に移動
    tags:
      - BoardHistories
    parameters:
      - name: game_id
        in: path
        required: true
        schema:
          type: integer
        description: ゲームID
      - name: move_number
        in: path
        required: true
        schema:
          type: integer
        description: 移動先の手数
      - name: branch
        in: query
        required: false
        schema:
          type: string
        description: 分岐名（デフォルト: main）
    responses:
      '200':
        description: 局面移動成功
        content:
          application/json:
            schema:
              type: object
              properties:
                game_id:
                  type: integer
                board_id:
                  type: integer
                move_number:
                  type: integer
                sfen:
                  type: string
      '404':
        description: 指定した手数が見つからない
        content:
          application/json:
            schema:
              type: object
              properties:
                error:
                  type: string
                status:
                  type: integer
```

### 4. 分岐切り替え

#### リクエスト

```
POST /api/v1/games/:game_id/switch_branch/:branch_name
```

**URLパラメータ**:
- `game_id` (必須) - ゲームのID
- `branch_name` (必須) - 切り替え先の分岐名

#### レスポンス

**成功時 (200 OK)**:
```json
{
  "game_id": 123,
  "branch": "main_1",
  "current_move_number": 10
}
```

**エラー時 (404 Not Found)**:
```json
{
  "error": "Branch not found",
  "status": 404
}
```

#### OpenAPI Specification

```yaml
/api/v1/games/{game_id}/switch_branch/{branch_name}:
  post:
    summary: 分岐切り替え
    tags:
      - BoardHistories
    parameters:
      - name: game_id
        in: path
        required: true
        schema:
          type: integer
        description: ゲームID
      - name: branch_name
        in: path
        required: true
        schema:
          type: string
        description: 切り替え先の分岐名
    responses:
      '200':
        description: 分岐切り替え成功
        content:
          application/json:
            schema:
              type: object
              properties:
                game_id:
                  type: integer
                branch:
                  type: string
                current_move_number:
                  type: integer
      '404':
        description: 分岐が見つからない
        content:
          application/json:
            schema:
              type: object
              properties:
                error:
                  type: string
                status:
                  type: integer
```

### 5. 手の移動（既存APIの拡張）

#### リクエスト

```
POST /api/v1/games/:game_id/boards/:board_id/move
```

**URLパラメータ**:
- `game_id` (必須) - ゲームのID
- `board_id` (必須) - ボードのID

**リクエストボディ**:
```json
{
  "move": "7g7f",
  "move_number": 5,  // 任意：現在の手数
  "branch": "main"   // 任意：現在の分岐名
}
```

#### レスポンス

**成功時 (200 OK)**:
```json
{
  "status": true,
  "is_checkmate": false,
  "is_repetition": false,
  "is_repetition_check": false,
  "board_id": 456,
  "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1",
  "move_number": 6,
  "branch": "main"
}
```

**エラー時 (400 Bad Request)**:
```json
{
  "error": "Invalid move",
  "status": 400
}
```

#### OpenAPI Specification

```yaml
/api/v1/games/{game_id}/boards/{board_id}/move:
  post:
    summary: 手の移動
    tags:
      - Moves
    parameters:
      - name: game_id
        in: path
        required: true
        schema:
          type: integer
        description: ゲームID
      - name: board_id
        in: path
        required: true
        schema:
          type: integer
        description: ボードID
    requestBody:
      required: true
      content:
        application/json:
          schema:
            type: object
            required:
              - move
            properties:
              move:
                type: string
                description: 移動（例：7g7f）
              move_number:
                type: integer
                description: 現在の手数
              branch:
                type: string
                description: 現在の分岐名
    responses:
      '200':
        description: 移動成功
        content:
          application/json:
            schema:
              type: object
              properties:
                status:
                  type: boolean
                is_checkmate:
                  type: boolean
                is_repetition:
                  type: boolean
                is_repetition_check:
                  type: boolean
                board_id:
                  type: integer
                sfen:
                  type: string
                move_number:
                  type: integer
                branch:
                  type: string
      '400':
        description: 不正な移動
        content:
          application/json:
            schema:
              type: object
              properties:
                error:
                  type: string
                status:
                  type: integer
```

## スキーマ定義

### BoardHistory

```yaml
BoardHistory:
  type: object
  properties:
    id:
      type: integer
      description: 履歴レコードのID
    game_id:
      type: integer
      description: 関連するゲームのID
    sfen:
      type: string
      description: 局面のSFEN表記
    move_number:
      type: integer
      description: 手数
    branch:
      type: string
      description: 分岐名
    created_at:
      type: string
      format: date-time
      description: 作成日時
    updated_at:
      type: string
      format: date-time
      description: 更新日時
    notation:
      type: string
      nullable: true
      description: 棋譜表記（APIレスポンス時のみ）
  required:
    - game_id
    - sfen
    - move_number
    - branch
```

## API生成手順

### Rswagを使用したSwagger仕様の生成

1. Rswagテスト仕様を作成

```ruby
# spec/integration/api/v1/board_histories_spec.rb
require 'swagger_helper'

RSpec.describe 'API::V1::BoardHistories', type: :request do
  path '/api/v1/games/{game_id}/board_histories' do
    get '局面履歴の取得' do
      tags 'BoardHistories'
      produces 'application/json'
      
      parameter name: :game_id, in: :path, type: :integer, description: 'ゲームID'
      parameter name: :branch, in: :query, type: :string, required: false, description: '分岐名（デフォルト: main）'
      
      response '200', '履歴取得成功' do
        schema type: :array,
          items: {
            type: :object,
            properties: {
              id: { type: :integer },
              game_id: { type: :integer },
              sfen: { type: :string },
              move_number: { type: :integer },
              branch: { type: :string },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' },
              notation: { type: :string, nullable: true }
            }
          }
        
        let(:game_id) { Game.create(status: 'active').id }
        run_test!
      end
      
      response '404', 'ゲームが見つからない' do
        schema type: :object,
          properties: {
            error: { type: :string },
            status: { type: :integer }
          }
        
        let(:game_id) { 'invalid' }
        run_test!
      end
    end
  end
  
  # 他のエンドポイントも同様に定義...
end
```

2. Swagger仕様を生成

```bash
cd backend
rails rswag:specs:swaggerize
```

### TypeScriptクライアントの生成

1. フロントエンドディレクトリに移動

```bash
cd frontend
```

2. OpenAPI Generator設定を確認

`.openapi-generator-config.yaml`:
```yaml
additionalProperties:
  modelPropertyNaming: original
  apiPackage: shogi-gui/api
```

3. npmスクリプトを実行してAPIクライアントを生成

```bash
npm run generate-api
```

これにより、バックエンドのRswag仕様からTypeScriptのAPIクライアントが生成されます。

## エラーハンドリング

すべてのAPIは以下のような共通のエラーレスポンス形式を持ちます：

```json
{
  "error": "エラーメッセージ",
  "status": 404  // HTTPステータスコード
}
```

主なエラーコード：

- **400 Bad Request**: リクエストに問題がある場合
- **404 Not Found**: 指定されたリソースが見つからない場合
- **422 Unprocessable Entity**: バリデーションエラーの場合
- **500 Internal Server Error**: サーバー側のエラーの場合