# フェーズ3: フロントエンド基盤設計書

## 概要
- Pinia ストアの拡張
- 型定義の更新 (TypeScript)
- API クライアントの更新 (axios/Fetch)
- モード切替 UI コンポーネント (GameModeSelector) の実装

## 参照設計
- `frontend_design.md`
- `api_design.md`

## 実装タスク
- 1. `stores/mode.ts` にモード切替ロジックを追加
- 2. API クライアント (`services/api.ts`) にモード切替用エンドポイントを実装
- 3. `GameModeSelector.vue` コンポーネントを作成し、画面上部に配置
- 4. UI フォールバック／エラーハンドリング実装

## テスト要件
- コンポーネント単体テスト (Jest/Vitest)
- Pinia ストアのユニットテスト 