# 将棋GUI 手の履歴機能 - フロントエンド設計

## 概要

将棋GUIのフロントエンドにおいて、手の履歴を表示・操作するための機能を実装します。ユーザーが過去の手順を確認し、任意の局面に戻れるようにするUIコンポーネントを設計します。

## 技術スタック

- Vue.js 3
- TypeScript
- Pinia（状態管理）
- CSS（スタイリング）

## コンポーネント構成

### 1. MoveHistoryPanel.vue

手の履歴を表示・操作するためのメインコンポーネントです。

**機能:**
- 履歴リストの表示
- 現在の手番のハイライト
- 任意の手への移動機能
- 分岐の表示と切り替え

**実装構造:**
```vue
<template>
  <div class="move-history-panel">
    <div class="panel-header">
      <h3>棋譜</h3>
      <div class="branch-selector" v-if="branches.length > 1">
        <label for="branch-select">分岐:</label>
        <select id="branch-select" v-model="currentBranch" @change="onBranchChange">
          <option v-for="branch in branches" :key="branch" :value="branch">{{ branch }}</option>
        </select>
      </div>
    </div>
    
    <div class="moves-container">
      <div 
        v-for="(history, index) in boardHistories" 
        :key="index"
        :class="['move-item', { 'active': currentMoveIndex === index }]"
        @click="navigateToMove(index)"
      >
        <span class="move-number">{{ index + 1 }}.</span>
        <span class="move-notation">{{ formatMove(history) }}</span>
      </div>
    </div>
  </div>
</template>
```

**Props:**
- `gameId`: ゲームID（必須）

**データ:**
- `boardHistories`: 局面履歴の配列
- `branches`: 利用可能な分岐のリスト
- `currentBranch`: 現在選択中の分岐
- `currentMoveIndex`: 現在の手数インデックス
- `loading`: 読み込み中かどうか
- `error`: エラーメッセージ

**メソッド:**
- `fetchBoardHistories()`: 履歴を取得する
- `fetchBranches()`: 分岐リストを取得する
- `navigateToMove(index)`: インデックスで指定した手数の局面に移動
- `onBranchChange()`: 分岐を切り替える
- `formatMove(history)`: 棋譜表記をフォーマットする

**Watchers:**
- `props.gameId`: ゲームIDが変わったときに履歴と分岐を再取得
- `boardStore.boardHistories`: ストアの履歴が更新されたときにコンポーネントの状態を更新
- `boardStore.currentMoveIndex`: ストアの現在の手数が更新されたときにコンポーネントの状態を更新
- `boardStore.branches`: ストアの分岐リストが更新されたときにコンポーネントの状態を更新
- `boardStore.currentBranch`: ストアの現在の分岐が更新されたときにコンポーネントの状態を更新

### 2. ShogiBoard.vue の拡張

既存の将棋盤コンポーネントに手の履歴機能を統合しました。

**変更点:**
```vue
<template>
  <div class="game-info">
    <!-- 既存のUI要素 -->
  </div>

  <div class="shogi-container">
    <PiecesInHand class="pieces-in-hand-top" ... />
    <ShogiBoardGrid ... />
    <PiecesInHand class="pieces-in-hand-bottom" ... />
    
    <!-- 追加: 履歴パネル -->
    <div v-if="boardStore.game" class="move-history-container">
      <MoveHistoryPanel :game-id="boardStore.game.id" />
    </div>
  </div>

  <PromotionModal ... />
</template>
```

**スタイル変更:**
```css
.shogi-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

/* 履歴パネル用のスタイル */
.move-history-container {
  width: 200px;
  height: 400px;
  margin-left: 20px;
  order: 3;
}
```

## APIクライアント

フロントエンドでは以下のAPIエンドポイントを使用して棋譜を操作します：

```typescript
// api.ts（OpenAPI自動生成）の拡張部分
/**
 * 棋譜を取得する
 *
 * @tags BoardHistories
 * @name V1GamesBoardHistoriesList
 * @summary 局面履歴の取得
 * @request GET:/api/v1/games/{game_id}/board_histories
 */
v1GamesBoardHistoriesList: (
  gameId: number,
  query?: { 
    branch?: string 
  },
  params: RequestParams = {},
) => this.request<BoardHistory[], Error>({ ... }),

/**
 * 分岐リストを取得する
 *
 * @tags BoardHistories
 * @name V1GamesBoardHistoriesBranchesList
 * @summary 分岐リストの取得
 * @request GET:/api/v1/games/{game_id}/board_histories/branches
 */
v1GamesBoardHistoriesBranchesList: (gameId: number, params: RequestParams = {}) => 
  this.request<{ branches: string[] }, Error>({ ... }),

/**
 * 特定の手数に移動する
 *
 * @tags BoardHistories
 * @name V1GamesNavigateToCreate
 * @summary 特定の手数に移動
 * @request POST:/api/v1/games/{game_id}/navigate_to/{move_number}
 */
v1GamesNavigateToCreate: (
  gameId: number,
  moveNumber: number,
  query?: { branch?: string },
  params: RequestParams = {},
) => this.request<NavigateResponse, Error>({ ... }),

/**
 * 分岐を切り替える
 *
 * @tags BoardHistories
 * @name V1GamesSwitchBranchCreate
 * @summary 分岐切り替え
 * @request POST:/api/v1/games/{game_id}/switch_branch/{branch_name}
 */
v1GamesSwitchBranchCreate: (
  gameId: number,
  branchName: string,
  params: RequestParams = {},
) => this.request<SwitchBranchResponse, Error>({ ... }),
```

## 状態管理（Pinia Store）

手の履歴機能のための状態を管理するために、既存のボードストアを拡張しました：

```typescript
// BoardStateへの追加
export interface BoardState {
  // 既存の状態
  shogiData: ShogiData;
  stepNumber: number;
  activePlayer: Player | null;
  // ...

  // 盤面履歴関連の状態
  boardHistories: BoardHistory[];
  currentBranch: string;
  branches: string[];
  currentMoveIndex: number;
}

// 新しい型定義
export interface BoardHistory {
  id: number;
  game_id: number;
  sfen: string;
  move_number: number;
  branch: string;
  created_at: string;
  updated_at: string;
  notation: string | null;
  last_move_from?: string;
  last_move_to?: string;
  last_move_piece?: string;
  last_move_promoted?: boolean;
}

export interface BranchesResponse {
  branches: string[];
}

export interface NavigateResponse {
  game_id: number;
  board_id: number;
  move_number: number;
  sfen: string;
}
```

**ストアアクション:**
```typescript
// 盤面履歴関連のアクション
// 盤面履歴一覧の取得
async fetchBoardHistories(gameId: number, branch?: string) {
  if (!gameId) {
    console.error('Game ID is required');
    return { data: [] };
  }

  return await this.handleAsyncAction(async () => {
    const targetBranch = branch || this.currentBranch;
    const response = await api.api.v1GamesBoardHistoriesList(gameId, { branch: targetBranch });
    this.boardHistories = response.data as unknown as Types.BoardHistory[];
    if (this.boardHistories.length > 0) {
      // 最新の手数を現在の手数として設定
      const maxMoveNumber = Math.max(...this.boardHistories.map(h => h.move_number));
      this.currentMoveIndex = this.boardHistories.findIndex(h => h.move_number === maxMoveNumber);
    }
    return response;
  }, '盤面履歴の取得に失敗しました');
},

// 分岐一覧の取得
async fetchBranches(gameId: number) {
  if (!gameId) {
    console.error('Game ID is required');
    return { data: { branches: ['main'] } };
  }

  return await this.handleAsyncAction(async () => {
    const response = await api.api.v1GamesBoardHistoriesBranchesList(gameId);
    this.branches = (response.data as unknown as Types.BranchesResponse).branches;
    return response;
  }, '分岐一覧の取得に失敗しました');
},

// 特定の手数に移動
async navigateToMove(params: { gameId: number, moveNumber: number }) {
  const { gameId, moveNumber } = params;
  if (!gameId || moveNumber === undefined) {
    console.error('Game ID and move number are required');
    return;
  }

  return await this.handleAsyncAction(async () => {
    const response = await api.api.v1GamesNavigateToCreate(
      gameId,
      moveNumber,
      { branch: this.currentBranch }
    );
    
    // 盤面情報を更新
    const parsed = parseSFEN(response.data.sfen);
    this.shogiData.board = parsed.board;
    this.shogiData.piecesInHand = parsed.piecesInHand;
    this.activePlayer = parsed.playerToMove;
    this.stepNumber = parsed.moveCount;
    this.board_id = response.data.board_id;
    
    // 現在の手数インデックスを更新
    this.currentMoveIndex = this.boardHistories.findIndex(h => h.move_number === moveNumber);
    
    return response;
  }, '特定の手数への移動に失敗しました');
},

// 分岐切り替え
async switchBranch(params: { gameId: number, branchName: string }) {
  const { gameId, branchName } = params;
  if (!gameId || !branchName) {
    console.error('Game ID and branch name are required');
    return;
  }

  return await this.handleAsyncAction(async () => {
    const response = await api.api.v1GamesSwitchBranchCreate(
      gameId,
      branchName
    );
    
    // 盤面情報を更新
    const parsed = parseSFEN(response.data.sfen);
    this.shogiData.board = parsed.board;
    this.shogiData.piecesInHand = parsed.piecesInHand;
    this.activePlayer = parsed.playerToMove;
    this.stepNumber = parsed.moveCount;
    this.board_id = response.data.board_id;
    
    // 分岐を更新
    this.currentBranch = branchName;
    // 履歴を再取得
    await this.fetchBoardHistories(gameId, branchName);
    
    return response;
  }, '分岐切り替えに失敗しました');
}
```

## 指し手表記の実装

指し手の表示形式として、以下のフォーマットを使用します：

```typescript
// 指し手の表示形式をフォーマット
const formatMove = (history: BoardHistory): string => {
  if (!history || !history.last_move_from || !history.last_move_to) {
    return '開始局面';
  }
  
  const from = history.last_move_from;
  const to = history.last_move_to;
  const piece = history.last_move_piece || '';
  const promoted = history.last_move_promoted ? '成' : '';
  
  return `${to} ${piece}${promoted}`;
};
```

バックエンドでは、以下のように棋譜形式で表記を生成します：

```ruby
# 棋譜形式で手を表示 (backend/app/models/board_history.rb)
def to_kifu_notation
  move_info = get_move_info
  return nil unless move_info

  player_symbol = move_info[:player_type] == 'b' ? '▲' : '△'
  "#{player_symbol}#{move_info[:to_square]}#{move_info[:piece_type]}"
end
```

## UI設計

### レイアウト

```
+-------------------------------------------+
|            手数 X 手番 先手/後手           |
+-------------------------------------------+
|                                           |
| +-------+                       +------+  |
| |       |                       |棋譜| |
| |後手の持ち駒|                     +------+  |
| |       |                       |1. 7六歩  | |
| +-------+                       |2. 3四歩  | |
|                                 |3. 2二角  | |
| +-------------------+           |...      | |
| |                   |           +------+  |
| |                   |                     |
| |     将棋盤        |                     |
| |                   |                     |
| |                   |                     |
| +-------------------+                     |
|                                           |
| +-------+                                 |
| |       |                                 |
| |先手の持ち駒|                               |
| |       |                                 |
| +-------+                                 |
|                                           |
+-------------------------------------------+
```

### スタイル設計

```css
.move-history-panel {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  border: 1px solid #ccc;
  border-radius: 4px;
  overflow: hidden;
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background-color: #f5f5f5;
  border-bottom: 1px solid #ccc;
}

.moves-container {
  flex: 1;
  overflow-y: auto;
  padding: 8px;
}

.move-item {
  display: flex;
  padding: 4px 8px;
  cursor: pointer;
  border-radius: 4px;
  margin-bottom: 2px;
}

.move-item.active {
  background-color: #e3f2fd;
  font-weight: bold;
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