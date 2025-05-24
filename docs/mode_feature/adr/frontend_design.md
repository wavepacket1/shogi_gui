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
- 合法手チェック機能（基本的な将棋ルールに準拠）
- 局面コピー機能（SFEN形式）

## 3. コンポーネント構成

### 3.1 新規コンポーネント
- `GameModeSelector.vue`: モード切替タブの表示・切替制御
- `EditModePanel.vue`: 編集モード用パネルUI
- `CommentEditor.vue`: コメント編集コンポーネント
- `BranchManager.vue`: 分岐管理コンポーネント

### 3.2 既存コンポーネントの拡張
- `ShogiBoard.vue`: モード別の駒移動・編集制御
- `MoveHistoryPanel.vue`: 検討モード機能拡張

#### MoveHistoryPanel.vue 拡張詳細
```typescript
interface MoveHistoryPanelProps {
  gameId: number;
  mode: 'play' | 'edit' | 'study';
  allowEdit?: boolean;
  showComments?: boolean;
}

interface MoveHistoryState {
  comments: Record<number, Comment[]>; // board_history_id -> comments[]
  editingCommentId: number | null;
  autoSaveTimer: number | null;
  showBranchDialog: boolean;
  newBranchName: string;
}
```

**追加UI要素:**
- コメントアイコン（💬）: 各手順項目に表示
- 分岐作成ボタン（+）: ホバー時表示
- 手順削除ボタン（🗑️）: ホバー時表示
- 分岐削除ボタン: 分岐セレクタ横に表示
- 局面コピーボタン: ナビゲーションコントロール内

### 3.3 CommentEditor.vue 仕様
```vue
<template>
  <div class="comment-editor" v-if="visible">
    <div class="comment-header">
      <span class="comment-title">コメント</span>
      <button @click="close" class="close-btn">×</button>
    </div>
    <textarea 
      v-model="content"
      @input="onInput"
      :maxlength="1000"
      rows="5"
      placeholder="コメントを入力..."
      class="comment-textarea"
    />
    <div class="comment-footer">
      <span class="char-count">{{ content.length }}/1000</span>
      <div class="action-buttons">
        <button @click="deleteComment" v-if="commentId" class="delete-btn">削除</button>
        <div class="save-indicator">
          <span v-if="autoSaving" class="saving">保存中...</span>
          <span v-else-if="lastSaved" class="saved">保存済み</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
interface Props {
  visible: boolean;
  commentId?: number;
  initialContent?: string;
  boardHistoryId: number;
}

interface Emits {
  (e: 'close'): void;
  (e: 'save', content: string): void;
  (e: 'delete'): void;
}
</script>
```

### 3.4 BranchManager.vue 仕様
```vue
<template>
  <div class="branch-manager">
    <div class="branch-selector">
      <select v-model="currentBranch" @change="onBranchChange">
        <option v-for="branch in branches" :key="branch" :value="branch">
          {{ branch }}
        </option>
      </select>
      <button 
        v-if="currentBranch !== 'main'" 
        @click="deleteBranch"
        class="delete-branch-btn"
        title="分岐を削除"
      >
        🗑️
      </button>
    </div>
    
    <!-- 分岐作成ダイアログ -->
    <div v-if="showCreateDialog" class="branch-dialog">
      <div class="dialog-content">
        <h3>新しい分岐を作成</h3>
        <input 
          v-model="newBranchName" 
          @keyup.enter="createBranch"
          placeholder="分岐名（自動生成）"
          maxlength="20"
        />
        <div class="dialog-actions">
          <button @click="createBranch">作成</button>
          <button @click="cancelCreate">キャンセル</button>
        </div>
      </div>
    </div>
  </div>
</template>
```

## 4. 状態管理（Pinia）

### 4.1 モードステート (`stores/mode.ts`)
```typescript
interface ModeState {
  currentMode: 'play' | 'edit' | 'study';
  editState: EditState;
  studyState: StudyState;
}

interface StudyState {
  comments: Record<number, Comment[]>;
  editingCommentId: number | null;
  autoSaveTimer: number | null;
  showBranchDialog: boolean;
  selectedBranch: string;
}
```

### 4.2 検討モード専用ストア (`stores/study.ts`)
```typescript
export const useStudyStore = defineStore('study', {
  state: (): StudyState => ({
    comments: {},
    editingCommentId: null,
    autoSaveTimer: null,
    showBranchDialog: false,
    selectedBranch: 'main'
  }),

  actions: {
    // コメント管理
    async loadComments(boardHistoryId: number) {
      // API呼び出し
    },

    async saveComment(boardHistoryId: number, content: string) {
      // 自動保存ロジック
      if (this.autoSaveTimer) {
        clearTimeout(this.autoSaveTimer);
      }
      
      this.autoSaveTimer = setTimeout(async () => {
        // API呼び出し
      }, 3000);
    },

    async deleteComment(commentId: number) {
      // API呼び出し
    },

    // 分岐管理
    async createBranch(fromMoveNumber: number, branchName?: string) {
      // 分岐作成ロジック
    },

    async deleteBranch(branchName: string) {
      // 分岐削除ロジック
    },

    // 局面コピー
    async copyPosition(sfen: string) {
      await navigator.clipboard.writeText(sfen);
      // トースト通知
    }
  }
});
```

### 4.3 局面編集ステート (`stores/board.ts` 拡張)
- 編集履歴 (`EditHistoryEntry[]`) を保持し Undo/Redo をサポート

## 5. UI仕様

### 5.1 モード切替UI
- 画面上部にタブまたはドロップダウンを設置し、現在のモードを明示的に表示
- `<GameModeSelector>` コンポーネントで切替を実装

### 5.2 モード別UI要素
- **対局モード**: 基本盤面、持ち駒表示、手番表示、投了ボタン
- **編集モード**: 手番変更ボタン、駒配置/ドラッグ&ドロップ、成り/不成り切替
- **検討モード**: 棋譜表示パネル、分岐作成/切替、コメント入力エリア

### 5.3 検討モード詳細UI仕様

#### レイアウト
- 左側: 将棋盤（60%）
- 右側: MoveHistoryPanel（40%）

#### MoveHistoryPanel 詳細
**ヘッダー部分:**
- タイトル: "棋譜"
- 分岐セレクタ（複数分岐時のみ表示）
- 分岐削除ボタン（main以外選択時のみ）

**ナビゲーションコントロール:**
- |◀ ◀ ▶ ▶| ボタン
- 局面コピーボタン

**手順リスト:**
```scss
.move-item {
  display: flex;
  align-items: center;
  padding: 4px 8px;
  border-radius: 4px;
  
  &:hover {
    .action-buttons {
      opacity: 1;
    }
  }
  
  .move-number {
    min-width: 30px;
  }
  
  .move-notation {
    flex: 1;
  }
  
  .comment-icon {
    color: #999;
    cursor: pointer;
    
    &.has-comment {
      color: #1976d2;
    }
  }
  
  .action-buttons {
    opacity: 0;
    transition: opacity 0.2s;
    
    .create-branch-btn,
    .delete-move-btn {
      background: none;
      border: none;
      cursor: pointer;
      font-size: 12px;
    }
  }
}
```

#### 視覚的フィードバック
**分岐表示色:**
- main: #1976d2（青）
- variation-1: #388e3c（緑）
- variation-2: #f57c00（橙）
- variation-3: #7b1fa2（紫）

**状態インジケータ:**
```scss
.save-indicator {
  .saving {
    color: #ff9800;
    
    &::before {
      content: "⟳";
      animation: spin 1s linear infinite;
    }
  }
  
  .saved {
    color: #4caf50;
    
    &::before {
      content: "✓";
    }
  }
  
  .error {
    color: #f44336;
    
    &::before {
      content: "⚠";
    }
  }
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

### 5.4 UIモックアップ
- 対局モード: `ui_ux_mockup.html`
- 編集モード: `ui_ux_edit_mockup.html`
- 検討モード: `ui_ux_analysis_mockup.html`

### 5.5 スタイリング

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

.comment-editor {
  border: 1px solid #ddd;
  border-radius: 4px;
  background: white;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  
  .comment-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 8px 12px;
    border-bottom: 1px solid #eee;
    background: #f5f5f5;
  }
  
  .comment-textarea {
    width: 100%;
    border: none;
    padding: 8px;
    resize: vertical;
    font-family: inherit;
    
    &:focus {
      outline: none;
      box-shadow: inset 0 0 0 2px #1976d2;
    }
  }
  
  .comment-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 8px 12px;
    background: #f9f9f9;
    font-size: 12px;
  }
}

.branch-dialog {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  
  .dialog-content {
    background: white;
    padding: 20px;
    border-radius: 8px;
    min-width: 300px;
    
    h3 {
      margin: 0 0 16px 0;
    }
    
    input {
      width: 100%;
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      margin-bottom: 16px;
    }
    
    .dialog-actions {
      display: flex;
      gap: 8px;
      justify-content: flex-end;
    }
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

### 7.2 検討モード固有のエラー
- コメント保存失敗時のリトライ機能
- 分岐作成失敗時のエラー表示
- ネットワークエラー時の状態表示
- 非合法手入力時のエラー表示とガイダンス

### 7.3 操作制限
- 各モードで許可外の操作を無効化し、該当UI要素をグレイアウトまたは非表示
- 権限エラーや不正操作時はツールチップ/メッセージを表示

## 8. パフォーマンス最適化

### 8.1 コメント機能
- 表示中の手順のコメントのみ読み込み
- コメント編集中の自動保存（debounce: 3秒）
- 古いコメントのメモリキャッシュからの削除

### 8.2 分岐表示
- 大量分岐時の仮想スクロール
- 分岐切り替え時の差分更新

### 8.3 メモ化
```typescript
// パフォーマンス重要な計算の最適化
const computedBoardState = computed(() => {
  // 局面計算のキャッシュ
});

// 特定のアクションのメモ化
const memoizedValidation = memoize(validatePosition);
```

## 9. アクセシビリティ

### 9.1 キーボードショートカット
- ← → : 手順ナビゲーション
- Home/End : 最初/最後の局面
- Ctrl+C : 局面コピー
- ESC : コメント編集終了

### 9.2 スクリーンリーダー対応
- 適切なaria-label設定
- 役割（role）の明示
- フォーカス管理

## 10. 注意事項
- UI/UXの大幅な変更は禁止
- 技術スタックのバージョンを固定し、変更時は承認を要する
- 仕様変更時は各設計書を同時に更新

## 11. テスト仕様

### 11.1 ユニットテスト
```typescript
describe('GameModeSelector', () => {
  it('should change mode correctly', async () => {
    // テストケース実装
  });
  
  it('should show confirmation dialog when needed', async () => {
    // テストケース実装
  });
});

describe('CommentEditor', () => {
  it('should save comment automatically', async () => {
    // 自動保存テスト
  });
  
  it('should handle character limit', async () => {
    // 文字数制限テスト
  });
});

describe('BranchManager', () => {
  it('should create new branch', async () => {
    // 分岐作成テスト
  });
  
  it('should prevent deleting main branch', async () => {
    // main分岐削除防止テスト
  });
});
```

### 11.2 コンポーネントテスト
- モード切替UIの表示テスト
- 各モードでの操作テスト
- エラー表示のテスト
- コメント機能の統合テスト
- 分岐管理機能の統合テスト

### 11.3 統合テスト
- モード間の状態維持テスト
- データの永続化テスト
- 実際の操作シーケンスのテスト
- 検討モード全体フローのE2Eテスト

## 12. データ構造
詳細は `docs/mode_feature/data_models.md` を参照

## 13. アニメーションとトランジション

### 13.1 モード切替トランジション
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

### 13.2 コメント表示アニメーション
```scss
.comment-editor-enter-active,
.comment-editor-leave-active {
  transition: all 0.3s ease;
}

.comment-editor-enter-from,
.comment-editor-leave-to {
  opacity: 0;
  transform: translateY(-10px);
}
```

### 13.3 非同期処理
- モード切替時の重い処理の非同期化
- 編集履歴の遅延保存
- UIのプログレス表示
- コメント自動保存のdebounce処理
