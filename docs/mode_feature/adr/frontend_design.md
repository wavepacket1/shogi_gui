# モード切替機能 フロントエンド設計書

## 1. 概要
- 将棋GUIアプリケーションにおいて、以下の3つのモードを切り替えて使用できる機能を提供します。
  - 対局モード: 実際の対局を行う機能
  - 編集モード: 任意の局面を作成・編集する機能
  - 検討モード: 局面の再生・分岐検討・コメント追加機能

## 2. 機能要件

### 2.1 対局モード
- 通常の対局ルールに従い、先手・後手が交互に指し手を入力
- 駒の移動、持ち駒の使用、投了機能を提供

### 2.2 編集モード
- 任意の局面を作成・編集可能
- 駒の配置・成り/不成り切替、持ち駒操作、手番切替をサポート
- 編集完了後に対局モードまたは検討モードへ遷移可能

### 2.3 検討モード
- 棋譜の再生・分岐検討機能を提供
- 任意の局面移動、新規分岐の追加・削除、コメント追加機能

## 3. コンポーネント構成

- ### 3.1 新規コンポーネント
  - `GameModeSelector.vue`: モード切替タブの表示・切替制御
  - `EditModePanel.vue`: 編集モード用パネルUI

- ### 3.2 既存コンポーネントの変更
  - `ShogiBoard.vue`: モード別の駒移動・編集制御
  - `MoveHistoryPanel.vue`: 分岐編集・コメント入力UIを追加

## 4. 状態管理（Pinia）

- ### 4.1 モードステート (`stores/mode.ts`)
  - `currentMode`、`editState` などを管理
  - `changeMode` アクションでモード遷移検証を実装

- ### 4.2 局面編集ステート (`stores/board.ts` 拡張)
  - 編集履歴 (`EditHistoryEntry[]`) を保持し Undo/Redo をサポート

## 5. UI仕様

### 5.1 モード切替UI
- 画面上部にタブまたはドロップダウンを設置し、現在のモードを明示的に表示
- `<GameModeSelector>` コンポーネントで切替を実装

### 5.2 モード別UI要素
- **対局モード**: 基本盤面、持ち駒表示、手番表示、投了ボタン
- **編集モード**: 手番変更ボタン、駒配置/ドラッグ&ドロップ、成り/不成り切替
- **検討モード**: 棋譜表示パネル、分岐作成/切替、コメント入力エリア

### 5.3 UIモックアップ
- 対局モード: `ui_ux_mockup.html`
- 編集モード: `ui_ux_edit_mockup.html`
- 検討モード: `ui_ux_analysis_mockup.html`

### 5.4 スタイリング

```scss
.mode-selector {
  // モード切替UI用スタイル
  .mode-tab {
    padding: 8px 16px;
    border: none;
    border-bottom: 2px solid transparent;
    
    &.active {
      border-bottom-color: #1976d2;
      color: #1976d2;
    }
  }
}

.edit-mode-panel {
  // 編集モード用パネルのスタイル
  .piece-palette {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 8px;
    padding: 16px;
  }
}
```

## 6. モード切替フロー
- モード切替時に `currentMode` を更新する
- その他の盤面・手番等の状態はそのまま維持
- UI は `currentMode` を参照して動的に切り替え

## 7. エラーハンドリング

### 7.1 モード切替時のエラー
- 不正な局面での切替防止
- 未保存の変更がある場合の警告表示
- 編集モードでの無効な配置検出

### 7.2 操作制限
- 各モードで許可外の操作を無効化し、該当UI要素をグレイアウトまたは非表示
- 権限エラーや不正操作時はツールチップ/メッセージを表示

## 8. 注意事項
- UI/UXの大幅な変更は禁止
- 技術スタックのバージョンを固定し、変更時は承認を要する
- 仕様変更時は各設計書を同時に更新

## 9. テスト仕様

### 9.1 ユニットテスト

```typescript
describe('GameModeSelector', () => {
  it('should change mode correctly', async () => {
    // テストケース実装
  });
  
  it('should show confirmation dialog when needed', async () => {
    // テストケース実装
  });
});
```

### 9.2 コンポーネントテスト

- モード切替UIの表示テスト
- 各モードでの操作テスト
- エラー表示のテスト

### 9.3 統合テスト

- モード間の状態維持テスト
- データの永続化テスト
- 実際の操作シーケンスのテスト 

### エラーハンドリング
詳細は API エラー仕様書を参照

## 10. データ構造
詳細は `docs/mode_feature/data_models.md` を参照

## 11. アニメーションとトランジション

### 11.1 モード切替トランジション

```vue
<transition name="mode-change">
  <component :is="currentModeComponent" />
</transition>

<style>
.mode-change-enter-active,
.mode-change-leave-active {
  transition: opacity 0.3s ease;
}

.mode-change-enter-from,
.mode-change-leave-to {
  opacity: 0;
}
</style>
```

### 11.2 メモ化

```typescript
// パフォーマンス重要な計算の最適化
const computedBoardState = computed(() => {
  // 局面計算のキャッシュ
});

// 特定のアクションのメモ化
const memoizedValidation = memoize(validatePosition);
```

### 11.3 非同期処理

- モード切替時の重い処理の非同期化
- 編集履歴の遅延保存
- UIのプログレス表示
