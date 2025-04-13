# 投了機能仕様書

このディレクトリには投了機能に関する仕様書が含まれています。

## ドキュメント構成
- `database.md` - データベース設計仕様（テーブル設計、モデル定義など）
- `api.md` - API仕様（エンドポイント、リクエスト/レスポンス定義）
- `api_implementation.md` - API実装手順（Swagger定義、クライアント生成など）
- `frontend.md` - フロントエンド実装仕様（コンポーネント、状態管理など）
- `error_handling.md` - エラーハンドリング仕様
- `testing.md` - テスト仕様

## 実装手順

### 1. データベース実装
1. マイグレーションファイルの作成
   ```bash
   rails generate migration AddGameStatusToGames
   rails generate migration AddEndInfoToBoards
   ```
2. マイグレーションの実行
   ```bash
   rails db:migrate
   ```
3. モデルの拡張（Game, Board）
   - 定数定義
   - バリデーション追加
   - メソッド実装

### 2. API実装
1. Swagger定義の作成
   - `/api/v1/games/{id}/resign`エンドポイントの定義
   - リクエスト/レスポンスの定義

2. バックエンドAPI実装
   - コントローラーの実装
   - モデルの実装
   - テストの作成
   - Swagger定義の生成
   ```bash
   rake rswag:specs:swaggerize
   ```

3. フロントエンドAPIクライアント生成
   ```bash
   npx swagger-typescript-api generate \
     --path ../backend/swagger/v1/openapi.yaml \
     --output ./src/services/api \
     --name "api.ts"
   ```

### 3. フロントエンド実装
1. 型定義の追加
   - `types/game.ts`の拡張

2. Piniaストアの拡張
   - 状態の追加
   - アクション実装
   - エラーハンドリング

3. コンポーネント実装
   - `ResignButton.vue`の作成
   - スタイリング
   - 親コンポーネントへの統合

### 4. 動作確認項目
1. 基本機能
   - [ ] 投了ボタンの表示
   - [ ] 確認ダイアログの表示
   - [ ] 投了処理の実行
   - [ ] 対局状態の更新
   - [ ] 勝者表示の更新

2. エラー処理
   - [ ] 既に終了している対局での投了
   - [ ] 手番でないプレイヤーの投了
   - [ ] ネットワークエラー時の処理
   - [ ] エラーメッセージの表示

3. UI/UX
   - [ ] ボタンの無効化状態
   - [ ] ローディング表示
   - [ ] 確認ダイアログのデザイン
   - [ ] レスポンシブ対応

### 5. デプロイ手順
1. ステージング環境での確認
   - データベースマイグレーション
   - 機能テスト
   - エラーログの確認

2. 本番環境へのデプロイ
   - バックエンドデプロイ
   - フロントエンドデプロイ
   - データベースマイグレーション

## 注意事項
- データベースマイグレーション時はバックアップを取得
- APIの変更時は必ずSwagger定義を更新
- Swagger定義更新後は必ずクライアントを再生成
- RESTfulの原則に従ったAPI設計
- フロントエンドの変更は既存の対局機能に影響を与えないよう注意
- エラーハンドリングは全てのケースを考慮
- ユーザー体験を重視したUI/UXの実装 