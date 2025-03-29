# 将棋GUI 手の履歴機能 - フロントエンド設計

## 概要

将棋GUIのフロントエンドにおいて、手の履歴を表示・操作するための機能を実装します。ユーザーが過去の手順を確認し、任意の局面に戻れるようにするUIコンポーネントを設計します。

## 技術スタック

- Vue.js 3
- TypeScript
- Vue Router
- Vuex / Pinia（状態管理）
- SCSS / Tailwind CSS（スタイリング）

## コンポーネント構成

### 1. MoveHistoryPanel.vue

手の履歴を表示・操作するためのメインコンポーネントです。

**機能:**
- 履歴リストの表示
- 現在の手番のハイライト
- 任意の手への移動機能
- 分岐の表示と切り替え

**構成:**
```
<template>
  <div class="move-history-panel">
    <div class="panel-header">
      <h3>棋譜</h3>
      <div class="branch-selector">
        <select v-model="selectedBranch" @change="changeBranch">
          <option v-for="branch in branches" :key="branch" :value="branch">
            {{ branch }}
          </option>
        </select>
      </div>
    </div>
    
    <div class="move-list">
      <div 
        v-for="history in boardHistories" 
        :key="history.id"
        :class="['move-item', { 'current': history.move_number === currentMoveNumber }]"
        @click="navigateToMove(history.move_number)"
      >
        <span class="move-number">{{ history.move_number }}</span>
        <span class="notation">{{ history.notation || '開始局面' }}</span>
      </div>
    </div>
    
    <div class="navigation-controls">
      <button @click="navigateToFirst">|◀</button>
      <button @click="navigateToPrevious">◀</button>
      <button @click="navigateToNext">▶</button>
      <button @click="navigateToLast">▶|</button>
    </div>
  </div>
</template>
```

**Props:**
- `gameId`: ゲームID

**データ:**
- `boardHistories`: 局面履歴の配列
- `currentMoveNumber`: 現在の手数
- `selectedBranch`: 選択中の分岐
- `branches`: 利用可能な分岐のリスト

**メソッド:**
- `fetchHistories()`: 履歴を取得する
- `fetchBranches()`: 分岐リストを取得する
- `navigateToMove(moveNumber)`: 指定した手数の局面に移動
- `navigateToFirst()`: 最初の局面に移動
- `navigateToPrevious()`: 一手前に移動
- `navigateToNext()`: 一手先に移動
- `navigateToLast()`: 最後の局面に移動
- `changeBranch()`: 分岐を切り替える

### 2. ShogiBoard.vue の拡張

既存の将棋盤コンポーネントに手の履歴機能を連携させる必要があります。

**追加機能:**
- 局面の移動時に盤面を更新
- 局面を戻した後の新しい手による分岐の作成

**変更点:**
```vue
<template>
  <div class="game-container">
    <!-- 既存の将棋盤表示 -->
    <div class="board-area">
      <!-- 既存のコード -->
    </div>
    
    <!-- 追加: 履歴パネル -->
    <MoveHistoryPanel 
      v-if="boardStore.game" 
      :game-id="boardStore.game.id"
      @move-navigated="handleMoveNavigated"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import { useBoardStore } from '@/stores/board';
import MoveHistoryPanel from '@/components/MoveHistoryPanel.vue';

const boardStore = useBoardStore();

// 履歴から局面に移動した際の処理
const handleMoveNavigated = (moveNumber) => {
  console.log(`Navigated to move: ${moveNumber}`);
  // ここで盤面の状態を更新
};

// 手を指した際の処理を拡張して、履歴も保存するように
const makeMove = async (move) => {
  // 既存のコード

  // 分岐作成の判定
  if (boardStore.currentMoveNumber < boardStore.maxMoveNumber) {
    // 分岐作成のロジック
  }
  
  // 履歴の更新
  await boardStore.fetchBoardHistories();
};
</script>
```

## APIとの連携

フロントエンドは以下のAPIエンドポイントを利用します：

```typescript
// APIクライアント例
export class BoardHistoryApi {
  // 履歴の取得
  static async getBoardHistories(gameId: number, branch: string = 'main') {
    return apiClient.get(`/api/v1/games/${gameId}/board_histories`, { params: { branch } });
  }

  // 分岐リストの取得
  static async getBranches(gameId: number) {
    return apiClient.get(`/api/v1/games/${gameId}/board_histories/branches`);
  }

  // 指定した手数への移動
  static async navigateToMove(gameId: number, moveNumber: number, branch: string = 'main') {
    return apiClient.post(`/api/v1/games/${gameId}/navigate_to/${moveNumber}`, null, {
      params: { branch }
    });
  }

  // 分岐切り替え
  static async switchBranch(gameId: number, branchName: string) {
    return apiClient.post(`/api/v1/games/${gameId}/switch_branch/${branchName}`);
  }
}
```

## 状態管理

Vuexまたは Pinia ストアを使用して、局面履歴の状態を管理します。

```typescript
// board.ts (Pinia Store)
export const useBoardStore = defineStore('board', {
  state: () => ({
    game: null,
    board: null,
    boardHistories: [],
    currentMoveNumber: 0,
    maxMoveNumber: 0,
    availableBranches: ['main'],
    currentBranch: 'main'
  }),
  
  actions: {
    // 履歴の取得
    async fetchBoardHistories() {
      const response = await BoardHistoryApi.getBoardHistories(this.game.id, this.currentBranch);
      this.boardHistories = response.data;
      this.maxMoveNumber = this.boardHistories.length > 0 
        ? Math.max(...this.boardHistories.map(h => h.move_number))
        : 0;
    },
    
    // 分岐リストの取得
    async fetchBranches() {
      const response = await BoardHistoryApi.getBranches(this.game.id);
      this.availableBranches = response.data.branches;
    },
    
    // 指定手数への移動
    async navigateToMove(moveNumber) {
      const response = await BoardHistoryApi.navigateToMove(
        this.game.id, 
        moveNumber, 
        this.currentBranch
      );
      this.board = { id: response.data.board_id, sfen: response.data.sfen };
      this.currentMoveNumber = moveNumber;
    },
    
    // 分岐切り替え
    async switchBranch(branchName) {
      const response = await BoardHistoryApi.switchBranch(this.game.id, branchName);
      this.currentBranch = branchName;
      this.currentMoveNumber = response.data.current_move_number;
      await this.fetchBoardHistories();
    }
  }
});
```

## UI設計

### レイアウト

```
+------------------+----------------------+
|                  |                      |
|                  |   Move History       |
|                  |   +------------+     |
|                  |   | 0:初期局面  |     |
|   Shogi Board    |   | 1:▲７六歩  |     |
|                  |   | 2:△３四歩  |     |
|                  |   | 3:▲２六歩  |     |
|                  |   | 4:△８八角成 |     |
|                  |   +------------+     |
|                  |   [◀◀][◀][▶][▶▶]    |
|                  |                      |
+------------------+----------------------+
```

### スタイル設計

```scss
.move-history-panel {
  width: 250px;
  border: 1px solid #ccc;
  border-radius: 4px;
  padding: 10px;
  
  .panel-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;
    
    h3 {
      margin: 0;
      font-size: 16px;
    }
  }
  
  .move-list {
    max-height: 400px;
    overflow-y: auto;
    margin-bottom: 10px;
    
    .move-item {
      padding: 5px;
      cursor: pointer;
      display: flex;
      
      &:hover {
        background-color: #f0f0f0;
      }
      
      &.current {
        background-color: #e0f0ff;
        font-weight: bold;
      }
      
      .move-number {
        width: 30px;
      }
    }
  }
  
  .navigation-controls {
    display: flex;
    justify-content: space-between;
    
    button {
      flex: 1;
      margin: 0 2px;
      padding: 5px;
    }
  }
}

.game-container {
  display: flex;
  gap: 20px;
}
```

## インタラクション設計

1. **手の履歴表示**
   - 初期状態: ゲーム開始時の局面から現在までの手を時系列で表示
   - 現在の手: ハイライト表示
   - 未来の手: グレーアウト

2. **局面移動**
   - クリック操作: 手をクリックすると、その局面に移動
   - ボタン操作: 一手前/一手次/最初/最後の局面に移動

3. **分岐処理**
   - 過去の局面に戻った後、新しい手を指した場合:
     - 新しい分岐を作成
     - ユーザーに分岐名を入力するダイアログを表示（任意）
     - 作成した分岐に自動的に切り替え

4. **分岐切り替え**
   - セレクトボックスから分岐を選択
   - 選択した分岐の手順を表示
   - 盤面を該当分岐の最新局面に更新

## アクセシビリティ対応

- キーボードナビゲーション: 矢印キーで手を移動可能
- スクリーンリーダー対応: 適切なARIA属性の設定
- コントラスト比: WCAG 2.1 AAレベルに準拠

## 国際化対応

- 言語切り替え機能
- 棋譜表記の多言語対応（日本語/英語）

## テスト計画

1. **ユニットテスト**
   - 各コンポーネントのメソッドのテスト
   - storeアクションのテスト

2. **コンポーネントテスト**
   - MoveHistoryPanelの表示テスト
   - ユーザーイベント（クリック、選択）のテスト

3. **E2Eテスト**
   - 実際の操作シナリオに基づくテスト
   - 分岐作成から切り替えまでの一連の流れをテスト 