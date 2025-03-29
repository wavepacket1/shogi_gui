# 将棋GUI 手の履歴機能仕様書

## 概要
将棋の対局中に指した手を局面の履歴として保存し、任意の局面に戻れるようにする機能を実装する。

## データベース設計

### 1. 新しいテーブルの追加
```ruby
# board_histories テーブル
create_table :board_histories do |t|
  t.references :game, null: false, foreign_key: true
  t.string :sfen, null: false  # 局面のSFEN
  t.integer :move_number, null: false  # 手数
  t.string :branch, default: 'main'  # 分岐を管理するための列
  t.timestamps
end

# インデックス
add_index :board_histories, [:game_id, :move_number, :branch], unique: true
```

### 2. 既存モデルの変更
```ruby
# Game モデル
class Game < ApplicationRecord
  has_one :board, dependent: :destroy  # 既存の関連
  has_many :board_histories, dependent: :destroy  # 追加
  # ... 既存のコード ...
end

# Board モデル
class Board < ApplicationRecord
  belongs_to :game
  has_many :pieces, dependent: :destroy
  # ... 既存のコード ...
end
```

### 3. 新しいモデルの作成
```ruby
# BoardHistory モデル
class BoardHistory < ApplicationRecord
  belongs_to :game

  validates :sfen, presence: true
  validates :move_number, presence: true, uniqueness: { scope: [:game_id, :branch] }
  validates :branch, presence: true

  scope :ordered, -> { order(move_number: :asc) }
  scope :main_branch, -> { where(branch: 'main') }

  # 前の局面を取得
  def previous_board_history
    return nil if move_number <= 0
    game.board_histories.where(branch: branch)
                      .find_by(move_number: move_number - 1)
  end
  
  # 次の局面を取得
  def next_board_history
    game.board_histories.where(branch: branch)
                      .where('move_number > ?', move_number)
                      .order(move_number: :asc).first
  end

  # 最初の局面を取得
  def first_board_history
    game.board_histories.where(branch: branch).ordered.first
  end

  # 最後の局面を取得
  def last_board_history
    game.board_histories.where(branch: branch).ordered.last
  end

  # 前の局面との差分から手の情報を取得
  def get_move_info
    prev_history = previous_board_history
    return nil unless prev_history

    current_parsed = Parser::SfenParser.parse(sfen)
    previous_parsed = Parser::SfenParser.parse(prev_history.sfen)
    
    # 局面の差分から手の情報を計算
    calculate_move_info(current_parsed, previous_parsed)
  end

  # 棋譜形式で手を表示
  def to_kifu_notation
    move_info = get_move_info
    return nil unless move_info

    player_symbol = move_info[:player_type] == 'b' ? '▲' : '△'
    "#{player_symbol}#{move_info[:to_square]}#{move_info[:piece_type]}"
  end

  private

  def calculate_move_info(current, previous)
    # 局面の差分から手の情報を計算するロジック
    # 例：駒の位置の変化から移動元と移動先を特定
    # 例：駒の種類の変化から成り/不成りを判定
  end
end
```

## API設計

### 既存API

#### 1. ゲーム作成 API

```
POST /api/v1/games
```

**リクエスト形式:**
```
Content-Type: application/json
```

**リクエストボディ:**
```json
{
  "status": "active"
}
```

**リクエストボディの説明:**
- `status` (required): ゲームの状態（"active", "finished", "pause"のいずれか）

**正常系レスポンス (201):**
```json
{
  "game_id": 123,
  "status": "active",
  "board_id": 456
}
```

**異常系レスポンス:**

**422 Unprocessable Entity** - 無効なリクエストの場合
```json
{
  "error": "Status can't be blank"
}
```

#### 2. ゲーム取得 API

```
GET /api/v1/games/{id}
```

**パラメータ:**
- `id` (path, required): ゲームID

**正常系レスポンス (200):**
```json
{
  "id": 123,
  "status": "active",
  "created_at": "2023-01-01T00:00:00Z",
  "updated_at": "2023-01-01T00:00:01Z",
  "board": {
    "id": 456,
    "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0",
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-01T00:00:00Z",
    "game_id": 123
  }
}
```

**異常系レスポンス:**

**404 Not Found** - 指定されたゲームが存在しない場合
```json
{
  "status": "error",
  "message": "ゲームが見つかりません。"
}
```

#### 3. 入玉宣言 API

```
POST /api/v1/games/{game_id}/boards/{board_id}/nyugyoku_declaration
```

**パラメータ:**
- `game_id` (path, required): ゲームID
- `board_id` (path, required): ボードID

**リクエスト形式:**
```
Content-Type: application/json
```

**リクエストボディ:** なし

**正常系レスポンス (200):**
```json
{
  "status": "success",
  "game_id": 123,
  "board_id": 456
}
```

**失敗時レスポンス (200):**
```json
{
  "status": "failed",
  "message": "入玉宣言に失敗しました。"
}
```

**異常系レスポンス:**

**404 Not Found** - 指定されたゲームまたはボードが存在しない場合
```json
{
  "status": "error",
  "message": "ゲームまたは盤面が見つかりません。"
}
```

#### 4. ボード取得 API

```
GET /api/v1/boards/{id}
```

**パラメータ:**
- `id` (path, required): ボードID

**正常系レスポンス (200):**
```json
{
  "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0",
  "legal_flag": true
}
```

**異常系レスポンス:**

**404 Not Found** - 指定されたボードが存在しない場合
```json
{
  "status": "error",
  "message": "ボードが見つかりません。"
}
```

#### 5. デフォルトボード取得 API

```
GET /api/v1/boards/default
```

**正常系レスポンス (200):**
```json
{
  "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0",
  "legal_flag": true
}
```

#### 6. 駒の移動 API

```
PATCH /api/v1/games/{game_id}/boards/{board_id}/move
```

**パラメータ:**
- `game_id` (path, required): ゲームID
- `board_id` (path, required): ボードID

**リクエスト形式:**
```
Content-Type: application/json
```

**リクエストボディ:**
```json
{
  "move": "7g7f"
}
```

**リクエストボディの説明:**
- `move` (required): 指し手の表記（USI形式: 例 "7g7f"）

**正常系レスポンス (200):**
```json
{
  "status": true,
  "is_checkmate": false,
  "is_repetition": false, 
  "is_repetition_check": false,
  "board_id": 456,
  "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1"
}
```

**異常系レスポンス:**

**422 Unprocessable Entity** - 無効な手または反則手の場合
```json
{
  "status": false,
  "message": "Invalid move: 8h2b+",
  "board_id": 456,
  "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0"
}
```

**404 Not Found** - 指定されたゲームまたはボードが存在しない場合
```json
{
  "status": false,
  "message": "ゲームまたは盤面が見つかりません。"
}
```

### 新規追加API

### 1. 局面履歴の取得 API

```
GET /api/v1/games/{game_id}/board_histories
```

**パラメータ:**
- `game_id` (path, required): ゲームID
- `branch` (query, optional): 分岐名（デフォルト: 'main'）

**正常系レスポンス (200):**
```json
[
  {
    "id": 1,
    "game_id": 123,
    "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0",
    "move_number": 0,
    "branch": "main",
    "created_at": "2023-01-01T00:00:00Z",
    "updated_at": "2023-01-01T00:00:00Z",
    "notation": null
  },
  {
    "id": 2,
    "game_id": 123,
    "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1",
    "move_number": 1,
    "branch": "main",
    "created_at": "2023-01-01T00:00:01Z",
    "updated_at": "2023-01-01T00:00:01Z",
    "notation": "▲７六歩"
  }
]
```

**レスポンスの説明:**
- `id`, `game_id`, `sfen`, `move_number`, `branch`, `created_at`, `updated_at`: データベースに保存されているフィールド
- `notation`: データベースには保存されず、APIレスポンス時に`to_kifu_notation`メソッドで動的に計算される棋譜表記

**異常系レスポンス:**

**404 Not Found** - 指定されたゲームが存在しない場合
```json
{
  "error": "Game not found",
  "status": 404
}
```

**400 Bad Request** - 無効なパラメータが指定された場合
```json
{
  "error": "Invalid branch name",
  "status": 400
}
```

**500 Internal Server Error** - サーバー内部エラーが発生した場合
```json
{
  "error": "Internal server error",
  "status": 500
}
```

### 2. 分岐リストの取得 API

```
GET /api/v1/games/{game_id}/board_histories/branches
```

**パラメータ:**
- `game_id` (path, required): ゲームID

**正常系レスポンス (200):**
```json
{
  "branches": ["main", "branch_1", "branch_2"]
}
```

**異常系レスポンス:**

**404 Not Found** - 指定されたゲームが存在しない場合
```json
{
  "error": "Game not found",
  "status": 404
}
```

**500 Internal Server Error** - サーバー内部エラーが発生した場合
```json
{
  "error": "Internal server error",
  "status": 500
}
```

### 3. 指定した手数の局面に移動 API

```
POST /api/v1/games/{game_id}/navigate_to/{move_number}
```

**パラメータ:**
- `game_id` (path, required): ゲームID
- `move_number` (path, required): 移動先の手数
- `branch` (query, optional): 分岐名（デフォルト: 'main'）

**リクエスト形式:**
```
Content-Type: application/json
```

**リクエストボディ:** なし（パスとクエリパラメータで必要な情報を指定）

**正常系レスポンス (200):**
```json
{
  "game_id": 123,
  "board_id": 456,
  "move_number": 5,
  "sfen": "lnsgkgsnl/1r5b1/pp1pppppp/2p6/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL b - 5"
}
```

**異常系レスポンス:**

**404 Not Found** - 指定されたゲームが存在しない場合
```json
{
  "error": "Game not found",
  "status": 404
}
```

**404 Not Found** - 指定された手数が存在しない場合
```json
{
  "error": "Move number not found in branch",
  "status": 404
}
```

**400 Bad Request** - 無効なパラメータが指定された場合
```json
{
  "error": "Invalid move number or branch name",
  "status": 400
}
```

**500 Internal Server Error** - サーバー内部エラーが発生した場合
```json
{
  "error": "Internal server error",
  "status": 500
}
```

### 4. 分岐切り替え API

```
POST /api/v1/games/{game_id}/switch_branch/{branch_name}
```

**パラメータ:**
- `game_id` (path, required): ゲームID
- `branch_name` (path, required): 分岐名

**リクエスト形式:**
```
Content-Type: application/json
```

**リクエストボディ:** なし（パスパラメータで必要な情報を指定）

**正常系レスポンス (200):**
```json
{
  "game_id": 123,
  "branch": "branch_1",
  "current_move_number": 3
}
```

**異常系レスポンス:**

**404 Not Found** - 指定されたゲームが存在しない場合
```json
{
  "error": "Game not found",
  "status": 404
}
```

**404 Not Found** - 指定された分岐が存在しない場合
```json
{
  "error": "Branch not found",
  "status": 404
}
```

**400 Bad Request** - 無効なパラメータが指定された場合
```json
{
  "error": "Invalid branch name",
  "status": 400
}
```

**500 Internal Server Error** - サーバー内部エラーが発生した場合
```json
{
  "error": "Internal server error",
  "status": 500
}
```

### 5. MovesコントローラでのAPI拡張

既存の移動APIを拡張して、局面の履歴を保存するように修正します。

```
PATCH /api/v1/games/{game_id}/boards/{board_id}/move
```

**パラメータ:**
- `game_id` (path, required): ゲームID
- `board_id` (path, required): ボードID
- `move_number` (optional): 現在の手数（指定した場合、その手数から分岐を作成）
- `branch` (optional): 分岐名（デフォルト: 'main'）

**リクエスト形式:**
```
Content-Type: application/json
```

**リクエストボディ:**
```json
{
  "move": "7g7f",
  "move_number": 5,
  "branch": "branch_1"
}
```

**リクエストボディの説明:**
- `move` (required): 指し手の表記（USI形式: 例 "7g7f"）
- `move_number` (optional): 現在の手数（指定した場合、この手数から新しい分岐を作成）
- `branch` (optional): 分岐名（デフォルト: 'main'）

**正常系レスポンス:** 既存のレスポンスに以下を追加
```json
{
  "status": true,
  "is_checkmate": false,
  "is_repetition": false,
  "is_repetition_check": false,
  "board_id": 456,
  "sfen": "lnsgkgsnl/1r5b1/pp1pppppp/2p6/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL b - 5",
  "move_number": 6,
  "branch": "main"
}
```

**異常系レスポンス:**

**404 Not Found** - 指定されたゲームまたはボードが存在しない場合
```json
{
  "error": "Game or board not found",
  "status": 404
}
```

**400 Bad Request** - 無効な手または分岐の指定がされた場合
```json
{
  "error": "Invalid move parameters",
  "details": {
    "move_number": ["Must be a positive integer"],
    "branch": ["Invalid branch name format"]
  },
  "status": 400
}
```

**409 Conflict** - 分岐の作成で競合が発生した場合
```json
{
  "error": "Branch conflict",
  "message": "A branch with this name already exists at this move",
  "status": 409
}
```

**422 Unprocessable Entity** - 移動が成立しない場合（反則手など）
```json
{
  "error": "Invalid move",
  "message": "This move is not allowed in current position",
  "status": 422
}
```

**500 Internal Server Error** - サーバー内部エラーが発生した場合
```json
{
  "error": "Internal server error",
  "status": 500
}
```

## Rswag コマンドと手順

### 1. APIテスト仕様の作成

Rswagでは、APIのテスト仕様をRSpecで記述します。以下のように`spec/integration/api/v1/board_histories_spec.rb`を作成します。

```ruby
# board_histories_spec.rb
require 'swagger_helper'

RSpec.describe 'API::V1::BoardHistories', type: :request do
  path '/api/v1/games/{game_id}/board_histories' do
    # APIエンドポイントの仕様を定義
    # ...
  end
end
```

### 2. OpenAPI仕様の生成

テスト仕様ファイルを作成したら、以下のコマンドを実行してOpenAPI仕様を生成します：

```bash
# バックエンドディレクトリで実行
cd backend
bundle exec rake rswag:specs:swaggerize
```

これにより、`backend/swagger/v1/openapi.yaml`ファイルが更新され、新しいAPIエンドポイントが追加されます。

### 3. TypeScriptクライアントの生成

OpenAPI仕様が生成されたら、フロントエンド側でTypeScriptクライアントを生成します：

```bash
# フロントエンドディレクトリで実行
cd frontend
npm run generate-api
```

このコマンドは`package.json`の以下のスクリプトを実行します：

```json
"generate-api": "swagger-typescript-api --path /app/backend/swagger/v1/openapi.yaml --output ./src/services/api --name \"api.ts\""
```

これによって、`frontend/src/services/api/api.ts`ファイルが更新され、フロントエンドから新しいAPIを呼び出すためのクライアントコードが生成されます。

### 4. 開発サイクル

API開発の一般的な流れは以下の通りです：

1. バックエンドでRswag用のテスト仕様を作成/更新する
2. `rake rswag:specs:swaggerize`を実行してOpenAPI仕様を生成する
3. フロントエンドで`npm run generate-api`を実行してTypeScriptクライアントを更新する
4. フロントエンドで新しく生成されたAPIクライアントを使用する

## 機能要件

### 1. 局面の保存
- 各手を指した後の局面をSFEN形式で保存
- 手数も合わせて保存
- 初期局面も履歴に含める

### 2. 履歴の表示
- 局面の履歴を時系列で表示
- 各手の表示形式
  - 例：「▲７六歩 △３四歩 ▲２六歩 △８八角成」
- 現在の手番をハイライト表示
- 現在の局面から先の手は非表示ではなく、グレーアウトなどで区別

### 3. 局面の移動
- 任意の手をクリックしてその局面に戻れる
- 前後の手に移動するためのボタン
  - 一手戻る：`previous_board_history`メソッドを使用
  - 一手進める：`next_board_history`メソッドを使用
  - 最初の局面に戻る：`first_board_history`メソッドを使用
  - 最後の局面に進める：`last_board_history`メソッドを使用
- 進行方向の両方（過去・未来）へ移動可能
  - 局面を戻ってから別の手を指した場合は分岐として扱う
  - 分岐前の手順も履歴として保持し、いつでも戻れるようにする

### 4. 分岐手順の扱い
- 局面を戻った後に新しい手を指した場合
  - 元の手順はそのまま保持
  - 新しい手順を別の分岐として保存
  - UIで分岐を視覚的に表示（例：ツリー表示）
- 分岐間の切り替え
  - 各分岐にラベルを付けて区別できるようにする
  - 分岐リストから選択して切り替え可能

## 実装手順

1. データベース設計
   - BoardHistoryモデルの作成
   - マイグレーションファイルの作成
   - モデル間の関連付け

2. バックエンド実装
   - 局面の保存APIの実装
   - 履歴取得APIの実装
   - 局面移動APIの実装
   - 手の情報計算ロジックの実装
   - 分岐手順の管理機能実装

3. Rswagによる API ドキュメント生成
   - Board Histories API のテスト仕様作成
   - API ドキュメントの生成（`rake rswag:specs:swaggerize`）
   - フロントエンド用の TypeScript クライアントの生成（`npm run generate-api`）

4. フロントエンド実装
   - 履歴表示コンポーネントの作成
   - 局面移動UIの実装
   - 局面の保存処理の実装
   - 分岐表示コンポーネントの作成

5. テスト実装
   - モデルのテスト
   - コントローラーのテスト
   - フロントエンドのテスト

## 注意点
- 局面を戻した後に新しい手を指した場合、元の手順も保持する
- 入玉宣言などの特殊な手も履歴に記録する
- パフォーマンスを考慮し、必要に応じて履歴の取得をページネーションする
- 局面の移動時にアニメーションを付けて視覚的に分かりやすくする 