# フェーズ2: バックエンド API 設計書

## 概要
- モード切替機能に必要なバックエンド API を実装します。
  - ゲームモード変更エンドポイント
  - 編集・検討モードへの状態保存・復元ロジック
  - 分岐管理・コメント機能

## 参照設計
- `api_design.md`                    : API エンドポイント仕様
- `state_diagram_design.puml`       : モード遷移図
- `database_design.md`              : DB カラム設計

## 実装タスク
1. ルーティング定義（`config/routes.rb`）にモード切替・位置保存・コメント追加を追加
2. `GamesController` にモード変更アクションを実装
3. 新規モデル/サービスクラス（`ModeTransition`）の追加
4. 編集・検討モード用のコントローラアクション実装（`PositionsController`, `CommentsController`）
5. バリデーションロジックの実装（`GameMode`, `Position` 等）
6. rswag を使った Swagger 定義の更新・Swaggerize 実行
7. RSpec リクエストスペックの作成・実行

## テスト要件
- 正常系：全エンドポイントが仕様通りに 200 レスポンスを返す
- 異常系：不正リクエスト・存在しないリソースで 400/404/405/409 を返す
- トランザクション管理：状態保存／復元が一貫性を保つ 