# フェーズ5: 検討モード設計書

## 概要
- 検討モード（Study）での棋譜再生・分岐検討・コメント機能を実現します。
- MoveHistoryPanel を中心に以下を実装:
  - 任意の局面への移動 (ナビゲーション)
  - 新しい分岐の作成・選択
  - コメントの追加・編集

## 参照設計
- `frontend_design.md`                        : UI コンポーネント仕様
- `api_design.md`                             : コメント / 分岐管理 API
- `database_design.md`                        : 分岐・コメント用テーブル設計
- `state_preservation_design.md`              : 検討モードの状態保存・復元ロジック
- `state_diagram_design.puml`                 : Study ステートの遷移図

## 実装タスク
1. `MoveHistoryPanel.vue` に分岐表示・選択 UI を実装
2. コメント入力エリア／ダイアログを追加
3. 分岐作成／切替処理を Pinia ストアに追加
4. `CommentsController` および `BranchesController` に API 実装
5. モード切替時の状態保存・復元を統合（モード遷移処理）

## テスト要件
- コンポーネント単体テスト (Jest/Vitest)
- Pinia ストアユニットテスト
- 検討モード API リクエストスペック (RSpec)
- E2E テスト (Cypress) でシナリオ検証 