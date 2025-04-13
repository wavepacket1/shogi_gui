# モード切替機能 フロントエンド実装仕様書

## 1. コンポーネント構成

### 1.1 新規コンポーネント

#### GameModeSelector.vue
```vue
<template>
  <div class="mode-selector">
    <div class="mode-tabs">
      <button 
        v-for="mode in modes" 
        :key="mode.value"
        :class="['mode-tab', { active: currentMode === mode.value }]"
        @click="changeMode(mode.value)"
      >
        {{ mode.label }}
      </button>
    </div>
  </div>
</template>
```

#### EditModePanel.vue
```vue
<template>
  <div class="edit-mode-panel">
    <div class="piece-palette">
      <!-- 駒選択パレット -->
    </div>
    <div class="edit-controls">
      <!-- 編集用コントロール -->
    </div>
  </div>
</template>
```

### 1.2 既存コンポーネントの変更

#### ShogiBoard.vue
- モードに応じた駒の移動制御
- 編集モード時の駒配置ロジック
- 検討モード時の手順管理

#### MoveHistoryPanel.vue
- 検討モード時の分岐編集UI追加
- コメント入力機能の追加

## 2. 状態管理（Pinia）

### 2.1 モードステート

```typescript
// stores/mode.ts
export const useModeStore = defineStore('mode', {
  state: () => ({
    currentMode: GameMode.PLAY,
    previousMode: null,
    modeHistory: [],
    editState: {
      unsavedChanges: false,
      selectedPiece: null
    }
  }),
  
  actions: {
    async changeMode(newMode: GameMode) {
      // モード変更前の検証
      if (await this.validateModeChange(newMode)) {
        this.previousMode = this.currentMode;
        this.currentMode = newMode;
        this.modeHistory.push(newMode);
      }
    }
  }
});
```

### 2.2 局面編集ステート

```typescript
// stores/board.ts 拡張
interface EditHistoryEntry {
  type: 'place' | 'remove' | 'promote' | 'unpromote';
  piece: Piece;
  position: Position;
  timestamp: number;
}

interface EditState {
  history: EditHistoryEntry[];
  canUndo: boolean;
  canRedo: boolean;
}
```

## 3. インタラクション設計

### 3.1 モード切替フロー

1. ユーザーがモード切替ボタンをクリック
2. 現在の状態をチェック（未保存の変更など）
3. 必要に応じて確認ダイアログを表示
4. モード切替の実行
5. UI要素の更新

### 3.2 モード別操作

#### 対局モード
- 通常の対局ルールに従う
- 手番制限を適用
- 合法手チェックを実施

#### 編集モード
- クリックで駒を配置/除去
- ドラッグ&ドロップで駒を移動
- 右クリックで成り/不成り切替

#### 検討モード
- 任意のタイミングで指し手入力
- 分岐の作成と切替
- コメントの追加と編集

## 4. UI設計

### 4.1 全体レイアウト

```
+----------------------------------------+
|  モード切替タブ                         |
+----------------------------------------+
|        |                    |          |
| 持ち駒 |                    | モード別  |
|        |      将棋盤        | パネル   |
|        |                    |          |
|        |                    |          |
+----------------------------------------+
|            操作パネル                   |
+----------------------------------------+
```

### 4.2 スタイリング

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

## 5. エラーハンドリング

### 5.1 バリデーション

```typescript
interface ValidationResult {
  valid: boolean;
  message?: string;
}

// モード切替時のバリデーション
function validateModeChange(
  currentMode: GameMode,
  targetMode: GameMode,
  state: GameState
): ValidationResult {
  // 各種チェック実装
}
```

### 5.2 エラーメッセージ

- モード切替エラー
- 不正な操作
- データ保存エラー
- ネットワークエラー

## 6. アニメーションとトランジション

### 6.1 モード切替トランジション

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

## 7. パフォーマンス最適化

### 7.1 メモ化

```typescript
// パフォーマンス重要な計算の最適化
const computedBoardState = computed(() => {
  // 局面計算のキャッシュ
});

// 特定のアクションのメモ化
const memoizedValidation = memoize(validatePosition);
```

### 7.2 非同期処理

- モード切替時の重い処理の非同期化
- 編集履歴の遅延保存
- UIのプログレス表示

## 8. テスト仕様

### 8.1 ユニットテスト

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

### 8.2 コンポーネントテスト

- モード切替UIの表示テスト
- 各モードでの操作テスト
- エラー表示のテスト

### 8.3 統合テスト

- モード間の状態維持テスト
- データの永続化テスト
- 実際の操作シーケンスのテスト