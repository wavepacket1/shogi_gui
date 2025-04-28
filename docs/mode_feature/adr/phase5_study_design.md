# フェーズ5: 検討モード設計書

## 概要
- 検討モード（Study）での棋譜再生・分岐検討・コメント機能を実現します。
- MoveHistoryPanel を中心に以下を実装:
  - 任意の局面への移動
  - 新しい分岐の作成
  - 手順の削除
  - コメントの追加
- 対局モードのルール制約は適用しない

## 参照設計
- `frontend_design.md` : UI コンポーネント仕様
- `api_design.md`      : コメント管理 API
- `database_design.md` : コメント用テーブル設計

## 実装タスク
- 1. `MoveHistoryPanel.vue` に分岐表示・選択 UI を実装
- 2. コメント入力エリアを追加
- 3. 分岐作成／削除／切替処理を Pinia ストアに追加
- 4. `CommentsController` にコメントAPIを実装

## テスト要件
- コンポーネント単体テスト (Jest/Vitest)
- Pinia ストアユニットテスト
- API リクエストスペック (RSpec)
- E2E テスト (Cypress) でシナリオ検証 