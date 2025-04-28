# フェーズ2: バックエンド API 設計書

## 概要
- モード切替機能に必要なバックエンド API を実装します。
  - ゲームモード変更エンドポイント
  - 分岐管理・コメント機能

## 参照設計
- `api_design.md`                    : API エンドポイント仕様
- `database_design.md`              : DB カラム設計

## 実装タスク
1. ルーティング定義（`config/routes.rb`）にモード切替・コメント追加を追加
2. `GamesController` にモード変更アクション（`update mode`）を実装
3. コメント機能用のコントローラアクション実装（`CommentsController`）
4. バリデーションロジックの実装（`GameMode`, `Position` 等）
5. rswag を使った Swagger 定義の更新・Swaggerize 実行
6. RSpec リクエストスペックの作成・実行

## テスト要件
- 正常系：ゲームモード変更とコメント取得/追加が仕様通りに 200 レスポンスを返す
- 異常系：不正リクエスト・存在しないリソースで 400/404/405/409 を返す

## 実装状況

### 1. 完了した実装

#### APIエンドポイント
以下のAPIエンドポイントの実装が完了しています：

- **局面履歴関連**
  - `GET /api/v1/games/:game_id/board_histories` - 局面履歴の取得
  - `GET /api/v1/games/:game_id/board_histories/branches` - 分岐リストの取得
  - `POST /api/v1/games/:game_id/navigate_to/:move_number` - 指定した手数の局面に移動
  - `POST /api/v1/games/:game_id/switch_branch/:branch_name` - 分岐切り替え

- **手の移動関連**
  - `PATCH /api/v1/games/:game_id/boards/:board_id/move` - 手の移動（既存APIの拡張）

- **モード切替関連**
  - `POST /api/v1/games/:game_id/mode` - ゲームモードの切り替え

- **コメント関連**
  - `POST /api/v1/games/:game_id/moves/:move_number/comments` - コメント追加
  - `GET /api/v1/games/:game_id/moves/:move_number/comments` - コメント取得
  - `PATCH /api/v1/games/:game_id/moves/:move_number/comments/:id` - コメント更新
  - `DELETE /api/v1/games/:game_id/moves/:move_number/comments/:id` - コメント削除

#### モデル実装
以下のモデルが正しく実装されています：

- `Game` - モード属性の追加（play、edit、studyの3種類）
- `BoardHistory` - 局面履歴を保存するモデル
  - 分岐管理機能
  - 手のSFEN表現の保存
  - 棋譜表記変換機能
- `Comment` - コメント機能を実装するモデル

#### テスト実装
以下のテストの作成が完了しています：

- `board_history_spec.rb` - 局面履歴APIのテスト
  - 履歴取得
  - 分岐リスト取得
  - 局面移動
  - 分岐切り替え

- `moves_spec.rb` - 手の移動APIのテスト
  - 基本的な手の移動
  - 手数と分岐を指定した移動
  - 手の再生成
  - エラーケースの処理

- `games_spec.rb` - ゲームモード切替のテスト
  - モード変更の正常系
  - 不正なモード指定の異常系

- `comments_spec.rb` - コメント機能のテスト
  - コメント追加
  - コメント取得
  - コメント更新
  - コメント削除

#### FactoryBot ファクトリ
テスト用のファクトリが実装されています：

- `games.rb` - Gameモデルのファクトリ
- `boards.rb` - Boardモデルのファクトリ
- `board_histories.rb` - BoardHistoryモデルのファクトリ
- `comments.rb` - Commentモデルのファクトリ
- `users.rb` - Userモデルのファクトリ

### 2. 残タスク

#### rswag Swagger定義
- rswag を使った Swagger 定義の更新・Swaggerize 実行が完全に完了していないため、手動での調整が必要です。

### 3. 技術的メモ
- 既存のコードベースでは `Game` モデルに `mode` 属性が既に追加されており、基本的なモード切替の土台は実装済み
- `BoardHistory` モデルには分岐管理機能が実装済みで、APIも正常に動作することを確認
- `Validator` クラスによる指し手の検証機能は既に実装されており、不正な手の検出が可能
- rswagの設定に一部問題があるため、Swagger定義の自動生成には手動での調整が必要