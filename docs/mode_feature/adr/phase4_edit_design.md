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
   - **持ち駒のドラッグ&ドロップ**: 持ち駒を盤上に配置
     - 持ち駒を選択して盤上にドラッグ&ドロップ
     - 配置先に既に駒がある場合は、その駒を相手の持ち駒に移動

2. **クリック操作**: 持ち駒を盤上に配置
   - 持ち駒をクリックして選択状態にする
   - 盤上のマスをクリックして選択中の持ち駒を配置
   - 配置先に既に駒がある場合は、その駒を相手の持ち駒に移動

3. **ダブルクリック**: 駒の操作
   - 成れる駒（歩、香、桂、銀、角、飛）の場合:
     1. まず成り/不成りを切り替え
     2. その後、駒を回転（先手/後手を切り替え）
   - 成れない駒（金、玉）の場合:
     - 駒を回転（先手/後手を切り替え）
   - 操作の優先順位:
     1. 成り/不成りの切り替え（成れる駒の場合のみ）
     2. 駒の回転（すべての駒）
   - 例: 銀の場合
     - 1回目のダブルクリック: 成銀に
     - 2回目のダブルクリック: 成銀を後手に
     - 3回目のダブルクリック: 後手の成銀を不成に
     - 4回目のダブルクリック: 後手の銀を先手に

4. **右クリック/長押し**: 盤面から持ち駒への移動
   - 盤面上の駒を右クリックすると、その駒が盤面から取り除かれ持ち駒に追加
   - モバイルデバイスでは長押し操作で同様の動作
   - 駒の所有権はそのまま維持（先手の駒は先手の持ち駒に、後手の駒は後手の持ち駒になる）
   - 成駒の場合は基本形に戻して持ち駒に追加（例: 「と金」→「歩」として持ち駒に）

5. **手番切替ボタン**: 先手/後手の手番を切り替え
   - 配置時の駒の所有者（色）に影響

### 最小限のUI要素

- **保存ボタン**: 編集した盤面を保存
- **手番切替ボタン**: 先手/後手を切り替え
- **現在の手番表示**: どちらの手番で編集中かを表示

### 実装上の懸念点と対策

1. **ダブルクリックの判定精度**:
   - 懸念: ユーザーのダブルクリックの速度や精度に依存
   - 対策: 
     - 300msという適度な時間閾値を設定
     - 同じ位置でのクリックのみを有効とする
     - 必要に応じて閾値の調整が可能な設計

2. **操作の意図の明確化**:
   - 懸念: 成り/不成りと回転の両方が同じ操作で行われるため、ユーザーが意図しない操作になる可能性
   - 対策:
     - 操作の優先順位を明確に定義
     - 視覚的なフィードバックを強化（成り駒の表示、回転のアニメーション）
     - 必要に応じて操作の確認ダイアログを表示

3. **モバイルデバイスでの操作性**:
   - 懸念: タッチデバイスでのダブルクリックが難しい
   - 対策:
     - タッチデバイスでは長押しを代替操作として提供
     - タッチ操作の最適化（タッチ領域の拡大など）
     - 必要に応じて別の操作方式の提供を検討

4. **状態の一貫性**:
   - 懸念: 成り/不成りと回転の組み合わせによる状態の複雑化
   - 対策:
     - 状態遷移を明確に定義
     - 型安全性の確保
     - 状態変更時のバリデーション強化

5. **パフォーマンス**:
   - 懸念: 頻繁な状態更新による再レンダリングの負荷
   - 対策:
     - 状態更新の最適化
     - 不要な再レンダリングの防止
     - メモリ使用量の最適化

6. **エラーリカバリー**:
   - 懸念: 誤操作時の状態復元が困難
   - 対策:
     - 操作の履歴管理
     - 元に戻す機能の提供
     - 状態のバックアップ

7. **アクセシビリティ**:
   - 懸念: ダブルクリックが困難なユーザーへの対応
   - 対策:
     - 代替操作の提供
     - キーボード操作のサポート
     - スクリーンリーダー対応

これらの懸念点に対する対策を実装することで、より安定した操作性とユーザー体験を提供できます。また、実装時にはこれらの点を考慮し、必要に応じて設計の見直しや機能の追加を行うことが重要です。

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

### 成り/不成と駒の回転の実装詳細

#### 1. 駒の状態管理

```typescript
// types/shogi.ts
export type PieceType = 
  // 先手駒
  'P' | 'L' | 'N' | 'S' | 'G' | 'B' | 'R' | 'K' | // 通常駒
  '+P' | '+L' | '+N' | '+S' | '+B' | '+R' | // 成駒
  // 後手駒
  'p' | 'l' | 'n' | 's' | 'g' | 'b' | 'r' | 'k' | // 通常駒
  '+p' | '+l' | '+n' | '+s' | '+b' | '+r'; // 成駒

// 駒の種類と成り駒の対応を定義
export const PIECE_PROMOTION_MAP: Record<PieceType, PieceType> = {
  // 先手駒
  'P': '+P', '+P': 'P', // 歩
  'L': '+L', '+L': 'L', // 香
  'N': '+N', '+N': 'N', // 桂
  'S': '+S', '+S': 'S', // 銀
  'B': '+B', '+B': 'B', // 角
  'R': '+R', '+R': 'R', // 飛
  'G': 'G', // 金（成れない）
  'K': 'K', // 玉（成れない）
  // 後手駒
  'p': '+p', '+p': 'p', // 歩
  'l': '+l', '+l': 'l', // 香
  'n': '+n', '+n': 'n', // 桂
  's': '+s', '+s': 's', // 銀
  'b': '+b', '+b': 'b', // 角
  'r': '+r', '+r': 'r', // 飛
  'g': 'g', // 金（成れない）
  'k': 'k'  // 玉（成れない）
};

// 駒の回転（先手/後手）の対応を定義
export const PIECE_ROTATION_MAP: Record<PieceType, PieceType> = {
  // 通常駒
  'P': 'p', 'p': 'P', // 歩
  'L': 'l', 'l': 'L', // 香
  'N': 'n', 'n': 'N', // 桂
  'S': 's', 's': 'S', // 銀
  'G': 'g', 'g': 'G', // 金
  'B': 'b', 'b': 'B', // 角
  'R': 'r', 'r': 'R', // 飛
  'K': 'k', 'k': 'K', // 玉
  // 成駒
  '+P': '+p', '+p': '+P', // と
  '+L': '+l', '+l': '+L', // 成香
  '+N': '+n', '+n': '+N', // 成桂
  '+S': '+s', '+s': '+S', // 成銀
  '+B': '+b', '+b': '+B', // 馬
  '+R': '+r', '+r': '+R'  // 龍
};
```

#### 2. コンポーネントの実装

```typescript
// components/Board.vue
<script setup lang="ts">
import { ref } from 'vue';
import { useBoardStore } from '@/stores/board';
import { PieceType, PIECE_PROMOTION_MAP, PIECE_ROTATION_MAP } from '@/types/shogi';

const boardStore = useBoardStore();
const lastClickTime = ref<number>(0);
const lastClickPosition = ref<{ row: number; col: number } | null>(null);

// ダブルクリックの判定（300ms以内の連続クリック）
const isDoubleClick = (row: number, col: number): boolean => {
  const now = Date.now();
  const isDouble = lastClickPosition.value?.row === row && 
                  lastClickPosition.value?.col === col && 
                  now - lastClickTime.value < 300;
  
  lastClickTime.value = now;
  lastClickPosition.value = { row, col };
  
  return isDouble;
};

// 駒の操作ハンドラ
const handlePieceOperation = (row: number, col: number): void => {
  const piece = boardStore.getPieceAt(row, col);
  if (!piece) return;

  if (isDoubleClick(row, col)) {
    // 成れる駒の場合
    if (PIECE_PROMOTION_MAP[piece] && PIECE_PROMOTION_MAP[piece] !== piece) {
      boardStore.togglePromotion(row, col);
    }
    // すべての駒で回転可能
    boardStore.rotatePiece(row, col);
  }
};

// クリックイベントハンドラ
const onClick = (row: number, col: number): void => {
  handlePieceOperation(row, col);
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
        @click="onClick(rowIndex, colIndex)"
      >
        <div 
          v-if="cell" 
          class="piece"
          :class="{
            'piece-black': cell.toUpperCase() === cell,
            'piece-white': cell.toLowerCase() === cell,
            'piece-promoted': cell.startsWith('+')
          }"
        >
          {{ cell }}
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.piece {
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.5em;
  cursor: pointer;
  transition: transform 0.2s;
}

.piece-black {
  color: #000;
}

.piece-white {
  color: #666;
  transform: rotate(180deg);
}

.piece-promoted {
  font-weight: bold;
}

.piece:hover {
  transform: scale(1.1);
}

.piece-white:hover {
  transform: rotate(180deg) scale(1.1);
}
</style>
```

#### 3. Piniaストアの実装

```typescript
// stores/board.ts
import { defineStore } from 'pinia';
import { 
  PieceType, 
  PIECE_PROMOTION_MAP, 
  PIECE_ROTATION_MAP 
} from '@/types/shogi';

export const useBoardStore = defineStore('board', {
  state: () => ({
    board: Array(9).fill(null).map(() => Array(9).fill(null)),
    currentSide: 'b',
    gameId: null,
    unsavedChanges: false
  }),

  actions: {
    // 駒の取得
    getPieceAt(row: number, col: number): PieceType | null {
      return this.board[row][col];
    },

    // 成り/不成りの切り替え
    togglePromotion(row: number, col: number): void {
      const piece = this.board[row][col];
      if (!piece) return;

      const promotedPiece = PIECE_PROMOTION_MAP[piece];
      if (promotedPiece && promotedPiece !== piece) {
        this.board[row][col] = promotedPiece;
        this.unsavedChanges = true;
      }
    },

    // 駒の回転（先手/後手の切り替え）
    rotatePiece(row: number, col: number): void {
      const piece = this.board[row][col];
      if (!piece) return;

      const rotatedPiece = PIECE_ROTATION_MAP[piece];
      if (rotatedPiece) {
        this.board[row][col] = rotatedPiece;
        this.unsavedChanges = true;
      }
    },

    // 盤面の保存
    async saveBoard(): Promise<void> {
      if (!this.gameId) return;

      try {
        const response = await fetch('/api/v1/boards', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            game_id: this.gameId,
            sfen: this.toSfen(),
            mode: 'edit'
          })
        });

        if (response.ok) {
          this.unsavedChanges = false;
        } else {
          throw new Error('盤面の保存に失敗しました');
        }
      } catch (error) {
        console.error('盤面の保存中にエラーが発生しました:', error);
        throw error;
      }
    }
  }
});
```

#### 4. 実装のポイント

1. **ダブルクリックの判定**:
   - 300ms以内の連続クリックをダブルクリックとして判定
   - 同じ位置でのクリックのみを有効とする
   - タイミングの調整は必要に応じて変更可能

2. **駒の状態管理**:
   - 成り駒と通常駒の対応を明確に定義
   - 先手/後手の駒の対応を明確に定義
   - 型安全性を確保

3. **UI/UXの考慮**:
   - 駒の向きを視覚的に表現（後手駒は180度回転）
   - 成り駒は太字で表示
   - ホバー時のアニメーション効果
   - クリック時のフィードバック

4. **エラーハンドリング**:
   - 無効な操作の防止
   - エラー発生時の適切なフィードバック
   - 保存失敗時のエラーハンドリング

5. **パフォーマンスの考慮**:
   - 不要な再レンダリングの防止
   - メモリ使用量の最適化
   - 状態更新の効率化

この実装により、ユーザーは直感的に駒の操作ができ、視覚的なフィードバックも得られます。また、型安全性とエラーハンドリングにより、安定した動作が期待できます。

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