# 投了機能 実装TODOリスト

## バックエンド (Backend)

-   [x] データベースマイグレーション作成 (`AddResignInfoToGames`, `AddPlayerReferencesToGames`)
-   [x] `Game` モデル実装 (`resign!` メソッド、バリデーション、リレーション)
-   [x] `GameError` エラークラス作成
-   [x] `GamesController#resign` アクション実装
-   [x] ルーティング設定 (`config/routes.rb`)
-   [x] Swagger 定義作成・更新 (`swagger.yaml`, `rswag`)
-   [ ] `Game` モデルテスト作成・実行 (`spec/models/game_spec.rb`)
-   [x] APIリクエストテスト作成 (`spec/requests/api/v1/games_spec.rb`) - ※認証周りの確認必要
-   [ ] **認証問題の完全解決**: APIリクエストが正しく認証されることの確認

## フロントエンド (Frontend)

-   [x] APIクライアント生成・更新 (`src/services/api/api.ts`)
-   [x] API呼び出しコンポーザブル (`src/composables/useGameApi.ts`) 作成
-   [x] 投了ボタンコンポーネント (`src/components/game/ResignButton.vue`) 作成
-   [ ] **UIへの組み込み**: `GameBoard.vue` 等の適切な場所に `<ResignButton>` を配置し、表示・非表示ロジック（対局中、自分の手番など）を実装
-   [ ] **動作確認**: 投了ボタンクリック → 確認ダイアログ → API呼び出し → ゲーム状態更新（ストア経由）の流れを確認
-   [ ] 投了ボタンコンポーネントテスト (`ResignButton.spec.ts`) 作成・実行
-   [ ] (任意) E2Eテストケース追加

## ドキュメント

-   [x] データベース設計仕様 (`database.md`) 更新
-   [x] API仕様 (`api.md`, `api_implementation.md`) 更新
-   [x] エラーハンドリング仕様 (`error_handling.md`) 更新
-   [x] テスト仕様 (`testing.md`) 更新
-   [x] 実装注意点 (`implementation.md`) 更新
-   [x] **本TODOリスト (`todo.md`) 作成**
-   [ ] 全機能実装完了後、ドキュメント全体の最終レビュー

---

**現在の主なブロック**:

*   バックエンドの認証が正しく機能し、テストや実際のAPI呼び出しが通ること。
*   フロントエンドでの実際のUI組み込みと動作確認。

このTODOリストで実装状況を管理していきましょう。