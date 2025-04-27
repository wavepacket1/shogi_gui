# フェーズ3: フロントエンド基盤設計書

## 概要
- Pinia ストアの拡張
- 型定義の更新 (TypeScript)
- API クライアントの更新 (axios/Fetch)
- モード切替 UI コンポーネント (GameModeSelector) の実装

## 参照設計
- `frontend_design.md`
- `api_design.md`
- `state_diagram_design.puml`

## 実装タスク
1. `stores/mode.ts` にモード切替ロジックを追加
2. `stores/board.ts` に編集・検討モード向けステート管理を追加
3. API クライアント (`services/api.ts`) にモード切替用エンドポイントを実装
4. `GameModeSelector.vue` コンポーネントを作成し、画面上部に配置
5. UI フォールバック／エラーハンドリング実装

## テスト要件
- コンポーネント単体テスト (Jest/Vitest)
- Pinia ストアのユニットテスト
- モック API を利用したレイアウト・状態遷移の E2E テスト (Cypress) 