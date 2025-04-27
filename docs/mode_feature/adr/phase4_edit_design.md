# フェーズ4: 編集モード設計書

## 概要
- EditModePanelコンポーネントによる局面編集UI
- 駒配置/削除、持ち駒増減、成り/不成切替、手番設定機能
- 編集した局面の保存・読み込み

## 参照設計
- `frontend_design.md`                      : UI コンポーネント仕様
- `api_design.md`                           : 局面保存/読み込み API
- `database_design.md`                      : 編集用カラム追加設計
- `state_preservation_design.md`            : 状態保存/復元ロジック

## 実装タスク
1. `EditModePanel.vue` コンポーネント作成
2. 編集操作（配置/削除/成り切替）ロジック実装
3. Pinia ストア (`stores/board.ts`) で編集履歴管理
4. 編集モード用 API (PositionsController) 連携
5. 編集完了後の状態遷移ロジック実装（モード切替）

## テスト要件
- コンポーネント単体テスト（Jest/Vitest）
- Pinia ストアのユニットテスト
- 編集 API リクエストスペック（RSpec） 