# 技術スタックルール

## 使用技術一覧

### フロントエンド
- Vue.js 3.x
- TypeScript
- Vite
- Pinia (状態管理)
- swagger-typescript-api (APIクライアント生成)

### バックエンド
- Ruby on Rails 7.x
- PostgreSQL
- Redis (キャッシュ用)
- Rswagger (API仕様管理)

### 開発ツール
- Git
- Docker
- Docker Compose

### テスト
- Jest (フロントエンド)
- RSpec (バックエンド)

### その他
- ESLint
- Prettier
- Rubocop

## バージョン管理
- 技術スタックに記載されたバージョンは厳密に遵守してください
- バージョンアップが必要な場合は、必ず事前に承認を得てください

## フロントエンド
- Vue.js 3.xのComposition APIを使用してください
- TypeScriptの型定義を厳密に行ってください
- コンポーネントは単一責任の原則に従ってください
- Piniaを使用して状態管理を行ってください

## バックエンド
- Ruby on Rails 7.xの規約に従ってください
- データベースのマイグレーションは必ずバックアップを取ってから実行してください
- Redisのキャッシュ戦略は明確に文書化してください

## API開発
- APIの仕様は必ずRswaggerで管理してください
- バックエンド側のSwagger定義更新後は以下のコマンドを実行してください：
  ```bash
  rake rswag:specs:swaggerize
  ```
- フロントエンド側のAPIクライアント生成は以下のコマンドで行ってください：
  ```bash
  npx swagger-typescript-api generate \
    --path ../backend/swagger/v1/openapi.yaml \
    --output ./src/services/api \
    --name "api.ts"
  ```
- APIの変更があった場合は、必ず両方のコマンドを実行して同期を取ってください
- APIのエンドポイントはRESTfulの原則に従ってください
- APIのレスポンスは一貫した形式で返してください

## コード品質
- ESLintとPrettierのルールを厳密に遵守してください
- Rubocopの警告は全て解消してください
- テストカバレッジは80%以上を維持してください

## セキュリティ
- 依存パッケージの脆弱性は定期的にチェックしてください
- セキュリティ関連のアップデートは優先的に対応してください

## パフォーマンス
- フロントエンドのバンドルサイズを最適化してください
- バックエンドのクエリはN+1問題に注意してください
- Redisのキャッシュを効果的に活用してください

## デプロイメント
- Docker環境での動作を確認してください
- CI/CDパイプラインの設定を維持してください
- 本番環境へのデプロイは必ずレビューを経てください 