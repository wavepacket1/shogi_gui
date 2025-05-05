# フェーズ4: 編集モード設計書

## 概要
- 任意の局面を作成・編集可能
- 以下の操作が可能:
  - 駒の配置
  - 駒の成り/不成りの切り替え
  - 持ち駒の増減
  - 手番の切り替え
- 編集完了後、その局面から対局モードまたは検討モードへ遷移可能
- 編集完了の検知: 初期局面（SFENなど）との差分比較または `unsavedChanges` フラグによる制御

## 参照設計
- `frontend_design.md` : UI コンポーネント仕様
- `database_design.md` : 編集用カラム追加設計

## 実装方針

編集モードはシンプルな操作性を重視し、余分なUIパネルを極力減らした実装を目指します。

### 基本的な操作方法

1. **ドラッグ&ドロップ**: 盤面上の駒を別のマスに移動
   - 空のマスにドロップ: 駒を移動
   - 駒があるマスにドロップ: 駒を置き換え

2. **右クリック/長押し**: 駒の成り/不成りを切り替え
   - 成れる駒（歩、香、桂、銀、角、飛）の場合に有効
   - クリックするたびに成り/不成りが切り替わる

3. **ダブルクリック**: 駒を削除
   - マス上の駒を削除して空にする

4. **手番切替ボタン**: 先手/後手の手番を切り替え
   - 配置時の駒の所有者（色）に影響

### 最小限のUI要素

- **保存ボタン**: 編集した盤面を保存
- **手番切替ボタン**: 先手/後手を切り替え
- **現在の手番表示**: どちらの手番で編集中かを表示

### 実装上の留意点

### 手番と駒の所有者について

編集モードでは、「現在の手番」が重要な概念となります：

1. **手番の役割**:
   - 現在選択されている手番（先手/後手）によって、配置される駒の所有者（駒の色）が決まります。
   - 先手選択時：配置される駒は先手の駒（黒い駒）になります。
   - 後手選択時：配置される駒は後手の駒（白い駒）になります。

2. **手番切替ボタン**:
   - 明示的な「先手/後手切替ボタン」を用意します。
   - ボタンクリックで先手⇔後手を切り替えます。
   - 現在選択中の手番が常に視覚的にわかるようUIで表示します（例：「現在：先手配置モード」）。

3. **駒の表現**:
   - 先手の駒：上向き、一般的に黒色で表示
   - 後手の駒：下向き（180度回転）、一般的に白色で表示
   - 駒のドラッグ&ドロップ時やクリック配置時には、現在選択中の手番に応じた向き・色で駒が配置されます。

この仕組みにより、ユーザーは明示的に手番を切り替えながら、双方の駒を適切に配置できます。

### 実装上の注意点

- ドラッグ&ドロップのイベント処理を適切に実装
- タッチデバイスでも操作しやすいよう、長押しなどの代替操作を提供
- 編集モードで起きた変更は`unsavedChanges`フラグで管理
- 編集モード終了時に未保存の変更がある場合は確認ダイアログを表示

## 実装方法の詳細

各操作の技術的な実現方法について説明します。以下の実装例はTypeScriptを使用しています。

### 型定義

```typescript
// types/shogi.ts
export type PieceType = 
  'P' | 'L' | 'N' | 'S' | 'G' | 'B' | 'R' | 'K' | // 先手駒
  'p' | 'l' | 'n' | 's' | 'g' | 'b' | 'r' | 'k' | // 後手駒
  '+P' | '+L' | '+N' | '+S' | '+B' | '+R' | // 先手成駒
  '+p' | '+l' | '+n' | '+s' | '+b' | '+r' | // 後手成駒
  null; // 空のマス

export type PlayerSide = 'b' | 'w'; // b=先手(black), w=後手(white)

export interface Position {
  row: number;
  col: number;
}

export interface MoveInfo {
  from: Position;
  to: Position;
  piece: PieceType;
}

export interface BoardState {
  board: (PieceType)[][];
  currentSide: PlayerSide;
  gameId: number | null;
  unsavedChanges: boolean;
}
```

### ドラッグ&ドロップの技術詳細

#### dataTransferオブジェクト

ドラッグ&ドロップ操作において重要な役割を果たす`dataTransfer`オブジェクトについて説明します。

```typescript
// DataTransferオブジェクトの基本的な使い方
const onDragStart = (event: DragEvent, piece: PieceType, row: number, col: number): void => {
  if (!event.dataTransfer) return;
  
  // データの設定: ドラッグ中の駒の情報をJSON文字列として保存
  event.dataTransfer.setData('text/plain', JSON.stringify({ piece, row, col }));
  
  // ドラッグ操作の種類を設定（移動操作として指定）
  event.dataTransfer.effectAllowed = 'move';
  
  // ドラッグ中のカーソル表示用の画像を設定（オプション）
  // const img = document.createElement('img');
  // img.src = `/assets/pieces/${piece}.svg`;
  // event.dataTransfer.setDragImage(img, img.width / 2, img.height / 2);
};

// ドロップ先でのデータ取得例
const onDrop = (event: DragEvent): void => {
  event.preventDefault();
  
  // 設定したデータを取得して解析
  const data = event.dataTransfer?.getData('text/plain');
  if (data) {
    const { piece, row, col } = JSON.parse(data);
    // 取得したデータを使用して処理を実行
  }
};
```

**dataTransferオブジェクトの主な特徴と機能**:

1. **データの受け渡し**: 
   - `setData(format, data)`: ドラッグ元からドロップ先へデータを渡すために使用
   - `getData(format)`: ドロップ先でデータを取得するために使用
   - 複数のデータ形式（MIMEタイプ）を指定可能（`text/plain`, `text/html`, `application/json`など）

2. **ドラッグ効果の制御**:
   - `effectAllowed`: ドラッグ操作で許可される効果を設定（`none`, `copy`, `move`, `link`, `all`など）
   - `dropEffect`: 実際のドロップ操作で使用される効果を指定

3. **ビジュアル表現**:
   - `setDragImage(element, x, y)`: ドラッグ中に表示されるカスタム画像を設定
   - 将棋の駒をドラッグする場合、実際の駒の画像を使用することでUXを向上

4. **ブラウザ間の互換性**:
   - モダンブラウザで広くサポートされていますが、イベントハンドリングには若干の差異がある場合がある
   - TouchデバイスではHTML5 Drag and Drop APIの対応が限定的なため、別途タッチイベント処理が必要

5. **セキュリティ考慮事項**:
   - `dataTransfer`のデータはJavaScriptのみでアクセス可能
   - クロスブラウザ操作では制限があり、同一オリジン内での利用が基本

編集モードの実装では、`dataTransfer`オブジェクトを使用して駒の情報（種類と位置）をドラッグ元からドロップ先へ安全に受け渡すことが重要です。これにより、ユーザーが直感的に駒を移動できるインターフェースを実現できます。

### ドラッグ&ドロップの実装

```typescript
// Vue 3のコンポーネントでの実装例
<script setup lang="ts">
import { ref } from 'vue';
import { useBoardStore } from '@/stores/board';
import { Position, PieceType, MoveInfo } from '@/types/shogi';

const boardStore = useBoardStore();

interface DraggingPiece {
  piece: PieceType;
  row: number;
  col: number;
}

const draggingPiece = ref<DraggingPiece | null>(null);

// ドラッグ開始時のイベントハンドラ
const onDragStart = (event: DragEvent, piece: PieceType, row: number, col: number): void => {
  if (!event.dataTransfer) return;
  
  draggingPiece.value = { piece, row, col };
  // HTML5ドラッグ&ドロップAPIのデータ設定
  event.dataTransfer.setData('text/plain', JSON.stringify({ piece, row, col }));
  event.dataTransfer.effectAllowed = 'move';
};

// ドロップ可能領域のイベントハンドラ
const onDragOver = (event: DragEvent): void => {
  event.preventDefault(); // デフォルトの動作をキャンセルしてドロップを許可
};

// ドロップ時のイベントハンドラ
const onDrop = (event: DragEvent, toRow: number, toCol: number): void => {
  event.preventDefault();
  if (draggingPiece.value) {
    const { piece, row, col } = draggingPiece.value;
    // Piniaストアを使用して駒の移動を記録
    boardStore.movePiece({
      from: { row, col },
      to: { row: toRow, col: toCol },
      piece: piece
    });
    draggingPiece.value = null;
  }
};
</script>

<template>
  <div class="board">
    <div 
      v-for="(row, rowIndex) in boardStore.board" 
      :key="`row-${rowIndex}`" 
      class="board-row"
    >
      <div 
        v-for="(cell, colIndex) in row" 
        :key="`cell-${rowIndex}-${colIndex}`"
        class="board-cell"
        @dragover="onDragOver"
        @drop="onDrop($event, rowIndex, colIndex)"
      >
        <div 
          v-if="cell" 
          class="piece" 
          draggable="true"
          @dragstart="onDragStart($event, cell, rowIndex, colIndex)"
        >
          {{ cell }}
        </div>
      </div>
    </div>
  </div>
</template>
```

### 右クリック/長押しによる成り/不成り切り替え

```typescript
// Vue 3 コンポーネントでの実装例
<script setup lang="ts">
import { useBoardStore } from '@/stores/board';
import { PieceType } from '@/types/shogi';

const boardStore = useBoardStore();

// 右クリックイベントハンドラ
const onRightClick = (event: MouseEvent, row: number, col: number): void => {
  event.preventDefault(); // コンテキストメニューを表示しない
  const piece = boardStore.getPieceAt(row, col);
  
  if (piece && canPromote(piece)) {
    boardStore.togglePromotion(row, col);
  }
};

// タッチデバイス用の長押しイベント
let touchTimer: number | null = null;
const touchStart = (row: number, col: number): void => {
  touchTimer = window.setTimeout(() => {
    const piece = boardStore.getPieceAt(row, col);
    if (piece && canPromote(piece)) {
      boardStore.togglePromotion(row, col);
    }
  }, 500); // 500ms長押しで発動
};

const touchEnd = (): void => {
  if (touchTimer) {
    clearTimeout(touchTimer);
    touchTimer = null;
  }
};

// 駒が成れるかどうかのチェック関数
const canPromote = (piece: PieceType): boolean => {
  if (!piece) return false;
  
  // 成れる駒のリスト (歩、香、桂、銀、角、飛)
  const promotablePieces: PieceType[] = [
    'P', 'L', 'N', 'S', 'B', 'R', 
    'p', 'l', 'n', 's', 'b', 'r'
  ];
  return promotablePieces.includes(piece);
};
</script>

<template>
  <div class="board">
    <div 
      v-for="(row, rowIndex) in boardStore.board" 
      :key="`row-${rowIndex}`" 
      class="board-row"
    >
      <div 
        v-for="(cell, colIndex) in row" 
        :key="`cell-${rowIndex}-${colIndex}`"
        class="board-cell"
        @contextmenu="onRightClick($event, rowIndex, colIndex)"
        @touchstart="touchStart(rowIndex, colIndex)"
        @touchend="touchEnd"
      >
        <!-- ... セル内容 ... -->
      </div>
    </div>
  </div>
</template>
```

### ダブルクリックによる駒の削除

```typescript
// Vue 3 コンポーネントでの実装例
<script setup lang="ts">
import { useBoardStore } from '@/stores/board';

const boardStore = useBoardStore();

// ダブルクリックイベントハンドラ
const onDoubleClick = (row: number, col: number): void => {
  const piece = boardStore.getPieceAt(row, col);
  if (piece) {
    boardStore.removePiece(row, col);
  }
};
</script>

<template>
  <div class="board">
    <div 
      v-for="(row, rowIndex) in boardStore.board" 
      :key="`row-${rowIndex}`" 
      class="board-row"
    >
      <div 
        v-for="(cell, colIndex) in row" 
        :key="`cell-${rowIndex}-${colIndex}`"
        class="board-cell"
        @dblclick="onDoubleClick(rowIndex, colIndex)"
      >
        <!-- ... セル内容 ... -->
      </div>
    </div>
  </div>
</template>
```

### 手番切替ボタンと現在の手番表示

```typescript
// Vue 3 コンポーネントでの実装例
<script setup lang="ts">
import { useBoardStore } from '@/stores/board';

const boardStore = useBoardStore();

// 手番切替関数
const toggleSide = (): void => {
  boardStore.toggleCurrentSide();
};
</script>

<template>
  <div class="edit-controls">
    <div class="current-side">
      現在: {{ boardStore.currentSide === 'b' ? '先手配置モード' : '後手配置モード' }}
    </div>
    
    <button @click="toggleSide" class="toggle-side-btn">
      {{ boardStore.currentSide === 'b' ? '後手に切り替え' : '先手に切り替え' }}
    </button>
    
    <button @click="boardStore.saveBoard" class="save-btn">
      保存
    </button>
  </div>
</template>
```

### Pinia ストアの実装

```typescript
// stores/board.ts
import { defineStore } from 'pinia';
import axios from 'axios';
import { 
  PieceType, 
  PlayerSide, 
  Position, 
  MoveInfo, 
  BoardState 
} from '@/types/shogi';

export const useBoardStore = defineStore('board', {
  state: (): BoardState => ({
    board: Array(9).fill(null).map(() => Array(9).fill(null)), // 9x9の将棋盤
    currentSide: 'b', // 'b'=先手(black), 'w'=後手(white)
    gameId: null,
    unsavedChanges: false
  }),
  
  actions: {
    // 駒の移動
    movePiece(moveInfo: MoveInfo): void {
      const { from, to, piece } = moveInfo;
      
      this.board[to.row][to.col] = piece;
      
      // 元の位置にあった駒を消去（ドラッグ元の駒を消す）
      if (from.row !== undefined && from.col !== undefined) {
        this.board[from.row][from.col] = null;
      }
      
      this.unsavedChanges = true;
    },
    
    // 駒の削除
    removePiece(row: number, col: number): void {
      if (this.board[row][col]) {
        this.board[row][col] = null;
        this.unsavedChanges = true;
      }
    },
    
    // 成り/不成り切り替え
    togglePromotion(row: number, col: number): void {
      const piece = this.board[row][col];
      if (!piece) return;
      
      // 成り駒と通常駒の変換マップ
      const promotionMap: Record<PieceType, PieceType> = {
        'P': '+P', '+P': 'P',
        'L': '+L', '+L': 'L',
        'N': '+N', '+N': 'N',
        'S': '+S', '+S': 'S',
        'B': '+B', '+B': 'B',
        'R': '+R', '+R': 'R',
        'p': '+p', '+p': 'p',
        'l': '+l', '+l': 'l',
        'n': '+n', '+n': 'n',
        's': '+s', '+s': 's',
        'b': '+b', '+b': 'b',
        'r': '+r', '+r': 'r',
        'G': 'G', 'K': 'K', // 金と玉は成れないので自身を返す
        'g': 'g', 'k': 'k', // 金と玉は成れないので自身を返す
        'null': null // TypeScriptの型定義のため
      } as Record<PieceType, PieceType>;
      
      if (promotionMap[piece]) {
        this.board[row][col] = promotionMap[piece];
        this.unsavedChanges = true;
      }
    },
    
    // 手番の切り替え
    toggleCurrentSide(): void {
      this.currentSide = this.currentSide === 'b' ? 'w' : 'b';
    },
    
    // 駒の取得
    getPieceAt(row: number, col: number): PieceType {
      return this.board[row][col];
    },
    
    // 盤面をSFEN形式に変換
    toSfen(): string {
      // SFEN形式への変換ロジック
      // 実際の実装では、盤面状態を適切なSFEN文字列に変換する処理を記述
      let sfen = '';
      // ... SFEN変換ロジック ...
      
      return sfen;
    },
    
    // 盤面の保存（APIへの送信）
    async saveBoard(): Promise<any> {
      if (!this.gameId) return;
      
      try {
        const response = await axios.post('/api/v1/boards', {
          game_id: this.gameId,
          sfen: this.toSfen(),
          mode: 'edit'
        });
        
        if (response.status === 201) {
          this.unsavedChanges = false;
          return response.data;
        }
      } catch (error) {
        console.error('盤面の保存に失敗しました', error);
        throw error;
      }
    }
  }
});
```

### モバイルデバイス対応

タッチデバイスでのドラッグ&ドロップは、標準のHTML5 Drag and Drop APIが完全にサポートされていないため、追加の対応が必要です。

```typescript
// タッチ対応ドラッグ&ドロップのサポート
<script setup lang="ts">
import { ref } from 'vue';
import { useBoardStore } from '@/stores/board';
import { Position, PieceType } from '@/types/shogi';

interface TouchTarget {
  row: number;
  col: number;
  piece: PieceType;
}

const boardStore = useBoardStore();
const touchTarget = ref<TouchTarget | null>(null);

// タッチ開始時
const onTouchStart = (event: TouchEvent, row: number, col: number): void => {
  const piece = boardStore.getPieceAt(row, col);
  if (piece) {
    touchTarget.value = { row, col, piece };
  }
};

// タッチ移動時
const onTouchMove = (event: TouchEvent): void => {
  // タッチ移動の視覚的フィードバック（オプション）
};

// タッチ終了時
const onTouchEnd = (event: TouchEvent, row: number, col: number): void => {
  if (touchTarget.value) {
    const { row: fromRow, col: fromCol, piece } = touchTarget.value;
    
    // 同じ位置にタッチ終了した場合は無視
    if (fromRow === row && fromCol === col) return;
    
    // 駒の移動を実行
    boardStore.movePiece({
      from: { row: fromRow, col: fromCol },
      to: { row, col },
      piece
    });
    
    touchTarget.value = null;
  }
};
</script>

<template>
  <!-- タッチイベントの実装をここに -->
</template>
```

## 実装タスク（フロントエンド）
- 1. 盤面コンポーネントに編集モード用のイベントハンドラ追加
  - ドラッグ&ドロップ機能
  - 右クリック/ダブルクリック処理
  - 最小限の編集コントロールUI
- 2. 編集操作（配置/削除/成り切替）ロジック実装
- 3. Pinia ストア (`stores/board.ts`) で編集履歴管理

## 実装タスク（バックエンド）
- 1. `boards_controller.rb`の拡張
  - `create`アクションに`mode`パラメータ対応を追加
  - 編集モード時のバリデーション緩和機能実装
- 2. `Board`モデルの拡張
  - `custom_position`カラム追加（マイグレーション作成）
  - 編集モードで作成された局面を識別するフラグ
- 3. `Validator`クラスの拡張
  - 基本的なSFEN形式チェックメソッド追加
  - 完全な将棋ルールに基づくバリデーションメソッド追加
- 4. OpenAPI仕様書（Swagger）の更新
  - `POST /api/v1/boards`エンドポイントをswagger仕様に追加
  - 編集モード用のパラメータと返却値を定義

## データベース設計

### `custom_position`カラムの目的と必要性

`boards`テーブルに追加する`custom_position`カラム（boolean型）は以下の目的で使用します：

1. **局面の起源識別**
   - 通常の対局で生じた局面（false）と編集モードで作成された局面（true）を区別
   - 研究用や特殊な配置など、通常の対局では出現しない局面をマーク

2. **バリデーション制御**
   - 編集モードで作成された局面には通常とは異なるバリデーションルールを適用
   - 通常の対局では不正となる配置（例：二歩など）を編集モードでは許容する判断材料

3. **表示・動作の分岐**
   - UI上での表示方法の変更（例：「カスタム局面」の表示）
   - 特殊な局面からの対局開始時の挙動制御

4. **データ分析用途**
   - 将来的な機能拡張で「カスタム局面から始まった対局」などを分析する際の識別子

このカラムは単純なboolean値でありながら多目的に使用でき、編集モード機能の実装において重要な役割を果たします。

## API仕様
```yaml
POST /api/v1/boards
概要: 編集モードで作成した盤面をデータベースに保存する
パラメータ:
  - game_id: ゲームID (body)
  - sfen: 盤面情報のSFEN文字列 (body)
  - mode: 'edit'（編集モード用）(body)
レスポンス:
  201:
    description: 盤面保存成功
    content: 
      application/json:
        board:
          id: integer
          game_id: integer
          sfen: string
          custom_position: boolean
          updated_at: string
```

## テスト要件

### テスト戦略

基本的なテスト戦略として「実装と並行して段階的にテスト観点を拡充する」アプローチを取ります：

1. **初期段階**：基本的な機能単位の愚直なテスト実装
2. **実装進行時**：実装が進むにつれてエッジケースやバグ発見をテストに反映
3. **完成段階**：ユーザー操作を模した統合テストの追加

### フロントエンドテスト観点

#### コンポーネント単体テスト（Jest/Vitest）

1. **駒操作の基本機能テスト**
   - ドラッグ&ドロップ機能
     - 駒を空マスに移動できること
     - 駒が配置されているマスに別の駒をドロップした場合に置き換わること
     - マス外へのドロップが無効となること
   - 右クリック/長押し操作
     - 成れる駒の場合に成り/不成りが切り替わること
     - 成れない駒の場合に変化がないこと
   - ダブルクリック操作
     - 駒が正しく削除されること
     - 空のマスのダブルクリックが何も起こさないこと

2. **手番関連のテスト**
   - 手番切替機能が正しく動作すること
   - 手番切替後に配置される駒の所有者（色）が変わること
   - UI上で現在の手番が正しく表示されること

3. **駒の状態管理テスト**
   - 駒の成り/不成り状態が正しく保持されること
   - 複数の操作（移動→成り→移動）後も駒の状態が正しいこと

#### Pinia ストアのユニットテスト

1. **状態管理テスト**
   - 盤面状態の変更が正しく記録されること
   - アクション実行後の状態が期待通りであること
   - 手番切替が状態に正しく反映されること

2. **SFEN変換テスト**
   - 編集した盤面が正しいSFEN形式に変換されること
   - 特殊な配置（例：二歩など）が正しくSFEN形式で表現されること

3. **undo/redo機能テスト**（実装する場合）
   - 操作履歴が正しく記録されること
   - 元に戻す/やり直す機能が期待通りに動作すること

### バックエンドテスト観点

#### API テスト（RSpec）

1. **バリデーションテスト**
   - 通常モードと編集モードでのバリデーション挙動の違いを検証
   - 編集モードでは通常ルールの一部が緩和されることを確認
   - 極端なケース（駒が全くない、王がないなど）のハンドリング

2. **盤面保存機能テスト**
   - リクエストパラメータが正しく処理されること
   - `mode`パラメータに応じた処理が行われること
   - `custom_position`フラグが正しく設定されること
   - レスポンスが仕様通りに返されること

3. **エラーハンドリングテスト**
   - 無効なSFEN文字列に対する適切なエラーレスポンス
   - 不正なパラメータに対する適切なエラーレスポンス

---

なお、テスト観点は実装の進捗に合わせて適宜調整し、具体的なエッジケースや機能要件の変更を反映していきます。特に実装初期段階では基本機能の動作確認を優先し、実装が進むにつれてテストケースを拡充する戦略が効果的です。

### フロントエンドとバックエンドの連携

編集モードでの駒の移動や削除といった操作は、以下のように実装します：

#### 編集操作とバックエンド連携フロー

```
┌─────────────────────┐                         ┌───────────────────┐
│                     │                         │                   │
│   フロントエンド    │                         │   バックエンド    │
│   （ブラウザ側）    │                         │   （サーバー側）  │
│                     │                         │                   │
└──────────┬──────────┘                         └─────────┬─────────┘
           │                                              │
           │  ユーザーが駒を操作                          │
           │  (ドラッグ&ドロップ/右クリック/              │
           │   ダブルクリック)                            │
           │                                              │
           │  Piniaストア内で盤面状態を更新               │
           │  (フロントエンドのメモリ内のみで保持)        │
           │                                              │
           │  unsavedChanges = true に設定                │
           │                                              │
           │                                              │
       ┌───▼────────────────────────────────┐             │
       │                                     │             │
       │  編集操作を継続                     │             │
       │  (複数の駒の移動/削除/成り切替)     │             │
       │  ※すべてフロントエンド内で完結     │             │
       │                                     │             │
       └────────────────┬────────────────────┘             │
                        │                                  │
                        │  「保存」ボタンをクリック        │
                        │                                  │
                        │                                  │
┌───────────────────────▼──────────────────────┐          │
│                                              │          │
│  編集後の盤面状態をSFEN形式に変換           │          │
│  game_id, sfen, mode=editを含むリクエスト作成│          │
│                                              │          │
└───────────────────────┬──────────────────────┘          │
                        │                                  │
                        │                                  │
                        │  POST /api/v1/boards            │
                        └─────────────────────────────────►│
                                                           │
                                                          ┌▼─────────────────────┐
                                                          │                      │
                                                          │ バリデーション実行   │
                                                          │ (編集モード用の緩和  │
                                                          │  されたルール適用)   │
                                                          │                      │
                                                          └┬─────────────────────┘
                                                           │
                                                          ┌▼─────────────────────┐
                                                          │                      │
                                                          │ custom_position=true │
                                                          │ で盤面をDBに保存     │
                                                          │                      │
                                                          └┬─────────────────────┘
           ┌──────────────────────────────────────────────┘
           │
           │  レスポンス: 201 Created
           │  (保存された盤面情報)
           │
┌──────────▼───────────┐
│                      │
│  unsavedChanges =    │
│  false に設定        │
│                      │
└──────────────────────┘
```

#### 編集操作中のデータフロー

1. **編集モード中の操作**:
   - 駒の移動、削除、成り/不成り切り替えなどの操作は**すべてフロントエンド側**で行われます
   - 各操作はPiniaストア内のメモリ上の状態（`board`配列）に即時反映されます
   - 操作のたびに`unsavedChanges`フラグが`true`に設定されます
   - バックエンドとの通信は**この段階では発生しません**

2. **盤面の保存**:
   - ユーザーが「保存」ボタンをクリックした時点で初めてバックエンドとの通信が発生します
   - フロントエンドのPiniaストアは現在の盤面状態をSFEN形式に変換します
   - 変換されたSFEN文字列を含むリクエストをバックエンドに送信します:
     ```typescript
     POST /api/v1/boards
     {
       game_id: gameId,
       sfen: sfenString,
       mode: 'edit'
     }
     ```
   - バックエンドはリクエストを受け取り、編集モード用の緩和されたバリデーションを適用します
   - バリデーション成功後、`custom_position=true`を設定して盤面をデータベースに保存します
   - 保存成功後、フロントエンドで`unsavedChanges`フラグを`false`に設定します

3. **ページ離脱時の挙動**:
   - `unsavedChanges`フラグが`true`の状態でユーザーがページを離れようとすると、確認ダイアログを表示します
   - これにより、保存忘れによるデータ損失を防止します

#### 実装上のメリット

このアプローチには以下のようなメリットがあります：

1. **リアルタイムな操作感**:
   - すべての編集操作がフロントエンドで即時反映されるため、ユーザー体験が向上します
   - バックエンド通信のレイテンシによる遅延がなく、スムーズな操作感を提供できます

2. **ネットワークトラフィックの削減**:
   - 個々の編集操作ではなく、最終的な保存時のみバックエンドと通信するため、ネットワーク負荷を軽減できます
   - 特にモバイルなど回線が不安定な環境でも操作性を確保できます

3. **バッチ処理によるパフォーマンス向上**:
   - 個別の操作ではなく、最終的な盤面状態をまとめて処理できるため、サーバー側の負荷も軽減されます

### 型定義

// ... existing code ... 