<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed } from 'vue';
import { useBoardEditStore } from '@/store/board';
import { PieceType, NonNullPieceType, DraggingPiece, Position, MoveInfo } from '@/types/shogi';
import { pieceMapper } from '@/utils/pieceMapper';

const boardStore = useBoardEditStore();

// 選択中の持ち駒
const selectedHandPiece = ref<NonNullPieceType | null>(null);

// 先手の持ち駒を計算
const blackPieces = computed(() => {
  const result: Record<string, number> = {};
  // 大文字の駒（先手）を抽出
  for (const [piece, count] of Object.entries(boardStore.piecesInHand)) {
    if (piece === piece.toUpperCase() && !piece.startsWith('+')) {
      result[piece] = count;
    }
  }
  return result;
});

// 後手の持ち駒を計算
const whitePieces = computed(() => {
  const result: Record<string, number> = {};
  // 小文字の駒（後手）を抽出
  for (const [piece, count] of Object.entries(boardStore.piecesInHand)) {
    if (piece === piece.toLowerCase() && !piece.startsWith('+')) {
      result[piece] = count;
    }
  }
  return result;
});

// 駒台の駒をクリックした時の処理
const handleHandPieceClick = (piece: string) => {
  // 持ち駒の数が0より大きいかチェック
  if (!boardStore.piecesInHand[piece as NonNullPieceType] || 
      boardStore.piecesInHand[piece as NonNullPieceType] <= 0) return;
  
  // 駒を選択状態にする
  selectedHandPiece.value = piece as NonNullPieceType;
  console.log(`持ち駒を選択: ${piece}`);
};

// マスをクリックした時の処理
const handleCellClick = (row: number, col: number) => {
  // 持ち駒が選択されている場合
  if (selectedHandPiece.value) {
    const targetCell = boardStore.board[row][col];
    
    // マスが空いている場合のみ配置
    if (targetCell === null) {
      const piece = selectedHandPiece.value;
      // 駒を配置
      boardStore.board[row][col] = piece;
      // 持ち駒を減らす
      boardStore.usePieceFromHand(piece);
      // 選択状態をクリア
      selectedHandPiece.value = null;
      
      console.log(`駒を配置: ${piece} at ${row}-${col}`);
    }
  }
};

// ドラッグ中の駒情報
const draggingPiece = ref<DraggingPiece | null>(null);

// ドラッグ開始時のイベントハンドラ
const onDragStart = (event: DragEvent, piece: PieceType, row: number, col: number): void => {
  if (!event.dataTransfer) return;
  
  // デバッグ情報
  console.log('ドラッグ開始時の駒情報:', { 
    piece, 
    row, 
    col,
    isUpperCase: typeof piece === 'string' && 
                ((piece === piece.toUpperCase() && !piece.startsWith('+')) || 
                (piece.startsWith('+') && piece[1] === piece[1].toUpperCase()))
  });
  
  // 駒の情報を保存
  draggingPiece.value = { piece, row, col };
  
  // HTML5ドラッグ&ドロップAPIのデータ設定
  const data = JSON.stringify({ piece, row, col });
  event.dataTransfer.setData('text/plain', data);
  
  // ドラッグ中の視覚的な表示を設定
  const dragElement = event.target as HTMLElement;
  if (dragElement) {
    // ドラッグ画像を設定して見た目を維持
    event.dataTransfer.setDragImage(dragElement, 15, 15);
  }
  
  // 操作を移動に限定
  event.dataTransfer.effectAllowed = 'move';
};

// ドロップ可能領域のイベントハンドラ
const onDragOver = (event: DragEvent): void => {
  event.preventDefault(); // デフォルトの動作をキャンセルしてドロップを許可
};

// ドロップ時のイベントハンドラ
const onDrop = (event: DragEvent, toRow: number, toCol: number): void => {
  event.preventDefault();
  
  try {
    // dataTransferからデータを取得（優先）
    const dataTransferText = event.dataTransfer?.getData('text/plain');
    
    if (dataTransferText) {
      const parsedData = JSON.parse(dataTransferText);
      const { piece, row, col } = parsedData;
      
      console.log('ドロップ時のデータから取得:', { piece, row, col });
      
      // 同じ場所にドロップした場合は何もしない
      if (row === toRow && col === toCol) {
        return;
      }
      
      // 移動を実行
      boardStore.movePiece({
        from: { row, col },
        to: { row: toRow, col: toCol },
        piece
      });
    } else if (draggingPiece.value) {
      // フォールバック: draggingPiece.valueからの利用（通常はこちらは使用されない）
      const { piece, row, col } = draggingPiece.value;
      
      if (piece === null) return;
      
      // 同じ場所にドロップした場合は何もしない
      if (row === toRow && col === toCol) {
        return;
      }
      
      console.log('draggingPiece.valueからデータ取得:', { piece, row, col });
      
      // 移動を実行
      boardStore.movePiece({
        from: { row, col },
        to: { row: toRow, col: toCol },
        piece
      });
    } else {
      console.log('エラー: ドラッグデータが見つかりません');
    }
  } catch (error) {
    console.error('ドロップ処理でエラー:', error);
  } finally {
    // 常に状態をクリア
    draggingPiece.value = null;
  }
};

// 右クリックイベントハンドラ
const onRightClick = (event: MouseEvent, row: number, col: number): void => {
  event.preventDefault(); // コンテキストメニューを表示しない
  const piece = boardStore.getPieceAt(row, col);
  
  if (piece && boardStore.canPromote(piece)) {
    boardStore.togglePromotion(row, col);
  }
};

// ダブルクリックイベントハンドラ
const onDoubleClick = (row: number, col: number): void => {
  const piece = boardStore.getPieceAt(row, col);
  if (piece) {
    boardStore.removePiece(row, col);
  }
};

// 手番切替関数
const toggleSide = (): void => {
  boardStore.toggleCurrentSide();
};

// 盤面保存関数
const saveBoard = async (): Promise<void> => {
  try {
    await boardStore.saveBoard();
    alert('盤面を保存しました');
  } catch (error) {
    alert('保存に失敗しました');
    console.error(error);
  }
};

// 長押し検出用変数
let touchTimer: number | null = null;
const touchStart = (row: number, col: number): void => {
  touchTimer = window.setTimeout(() => {
    const piece = boardStore.getPieceAt(row, col);
    if (piece && boardStore.canPromote(piece)) {
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

// 駒表示用の関数
const getPieceDisplay = (piece: PieceType | string): string => {
  if (!piece) return '';
  
  // pieceMapperを使用して表示文字を返す
  if (typeof piece === 'string') {
    return pieceMapper[piece as keyof typeof pieceMapper] || piece;
  }
  
  return String(piece);
};

// ページ離脱時の確認
const beforeUnloadHandler = (event: BeforeUnloadEvent) => {
  if (boardStore.unsavedChanges) {
    event.preventDefault();
    event.returnValue = '';
    return '変更が保存されていません。このページを離れますか？';
  }
};

// ライフサイクルフック
onMounted(() => {
  window.addEventListener('beforeunload', beforeUnloadHandler);
  
  // ゲームIDの設定（実際のアプリではルートパラメータなどから取得）
  const urlParams = new URLSearchParams(window.location.search);
  const gameId = urlParams.get('gameId');
  if (gameId) {
    boardStore.setGameId(parseInt(gameId));
  }
  
  // 空の盤面で初期化
  boardStore.initializeEmptyBoard();
});

onBeforeUnmount(() => {
  window.removeEventListener('beforeunload', beforeUnloadHandler);
});
</script>

<template>
  <div class="edit-board-container">
    <div class="board-controls">
      <div class="current-side">
        現在: {{ boardStore.currentSide === 'b' ? '先手配置モード' : '後手配置モード' }}
      </div>
      
      <button @click="toggleSide" class="toggle-side-btn">
        {{ boardStore.currentSide === 'b' ? '後手に切り替え' : '先手に切り替え' }}
      </button>
      
      <button @click="saveBoard" class="save-btn" :disabled="!boardStore.gameId">
        保存
      </button>
    </div>
    
    <div class="board-area">
      <!-- 後手の駒台 -->
      <div class="pieces-in-hand">
        <div 
          v-for="(count, piece) in whitePieces" 
          :key="piece" 
          class="piece-container"
          @click="handleHandPieceClick(piece)"
        >
          <div class="piece-shape" :class="{ 'w': true }">
            <div class="piece-symbol">{{ getPieceDisplay(piece) }}</div>
            <div class="piece-count" v-if="count > 0">{{ count }}</div>
          </div>
        </div>
      </div>
      
      <!-- 将棋盤 -->
      <div class="shogi-board">
        <div 
          v-for="(row, rowIndex) in boardStore.board" 
          :key="`row-${rowIndex}`" 
          class="shogi-row"
        >
          <div 
            v-for="(cell, colIndex) in row" 
            :key="`cell-${rowIndex}-${colIndex}`"
            class="shogi-cell"
            @dragover="onDragOver"
            @drop="onDrop($event, rowIndex, colIndex)"
            @dblclick="onDoubleClick(rowIndex, colIndex)"
            @contextmenu="onRightClick($event, rowIndex, colIndex)"
            @touchstart="touchStart(rowIndex, colIndex)"
            @touchend="touchEnd"
            @click="handleCellClick(rowIndex, colIndex)"
          >
            <div 
              v-if="cell" 
              class="piece-shape"
              :class="{ 
                'b': typeof cell === 'string' && ((cell === cell.toUpperCase() && !cell.startsWith('+')) || (cell.startsWith('+') && cell[1] === cell[1].toUpperCase())), 
                'w': typeof cell === 'string' && ((cell === cell.toLowerCase() && !cell.startsWith('+')) || (cell.startsWith('+') && cell[1] === cell[1].toLowerCase())),
                'b-promoted': typeof cell === 'string' && cell.startsWith('+') && cell[1] === cell[1].toUpperCase(),
                'w-promoted': typeof cell === 'string' && cell.startsWith('+') && cell[1] === cell[1].toLowerCase()
              }"
              :data-piece="cell"
              :data-row="rowIndex"
              :data-col="colIndex"
              :data-owner="typeof cell === 'string' && ((cell === cell.toUpperCase() && !cell.startsWith('+')) || (cell.startsWith('+') && cell[1] === cell[1].toUpperCase())) ? '先手' : '後手'"
              draggable="true"
              @dragstart="onDragStart($event, cell, rowIndex, colIndex)"
            >
              <div class="piece-symbol">{{ getPieceDisplay(cell) }}</div>
            </div>
          </div>
        </div>
      </div>
      
      <!-- 先手の駒台 -->
      <div class="pieces-in-hand">
        <div 
          v-for="(count, piece) in blackPieces" 
          :key="piece" 
          class="piece-container"
          @click="handleHandPieceClick(piece)"
        >
          <div class="piece-shape" :class="{ 'b': true }">
            <div class="piece-symbol">{{ getPieceDisplay(piece) }}</div>
            <div class="piece-count" v-if="count > 0">{{ count }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.edit-board-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 20px;
  max-width: 600px;
  margin: 0 auto;
}

.board-controls {
  display: flex;
  justify-content: space-between;
  width: 100%;
  margin-bottom: 20px;
  padding: 10px;
  background-color: #f0f0f0;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.current-side {
  font-weight: bold;
  padding: 8px;
  color: #333;
}

button {
  padding: 8px 16px;
  border-radius: 4px;
  border: none;
  cursor: pointer;
  font-weight: bold;
  transition: background-color 0.3s;
}

button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.toggle-side-btn {
  background-color: #3498db;
  color: white;
}

.toggle-side-btn:hover {
  background-color: #2980b9;
}

.save-btn {
  background-color: #2ecc71;
  color: white;
}

.save-btn:hover {
  background-color: #27ae60;
}

.board-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
}

/* 駒台のスタイル */
.pieces-in-hand {
  display: flex;
  justify-content: center;
  gap: 12px;
  width: 450px;
  padding: 10px;
  background: rgba(244, 240, 236, 0.9);
  border-radius: 8px;
  flex-wrap: wrap;
}

.piece-container {
  perspective: 600px;
  cursor: pointer;
}

.piece-count {
  position: absolute;
  bottom: 2px;
  right: 2px;
  font-size: 10px;
  color: #000000;
  background: rgba(255, 255, 255, 0.8);
  padding: 0px 2px;
  border-radius: 2px;
  transform-origin: center;
  text-shadow: 0 1px 1px rgba(255, 255, 255, 0.8);
}

/* 将棋盤のスタイリング - ShogiBoardGridのスタイルを適用 */
.shogi-board {
  display: grid;
  grid-template-rows: repeat(9, 50px);
  grid-template-columns: repeat(9, 50px);
  border: 3px solid #4A3728;
  width: 450px;
  height: 450px;
  margin: 10px auto;
  background-color: #E8C99B;
  box-shadow: 
      0 4px 8px rgba(0, 0, 0, 0.2),
      inset 0 0 20px rgba(0, 0, 0, 0.1);
}

.shogi-row {
  display: contents;
}

.shogi-cell {
  border: 1px solid #8B7355;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  background-color: #E8C99B;
}

.piece-shape {
  cursor: grab;
  width: 30px;
  height: 45px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  position: relative;
  transition: none;
  clip-path: polygon(
      50% 0%,
      100% 35%,
      100% 100%,
      0% 100%,
      0% 35%
  );
  background: 
      repeating-linear-gradient(
          -65deg,
          #C4A36B 0px,
          #C4A36B 4px,
          #B49355 4px,
          #B49355 8px
      ),
      linear-gradient(
          155deg,
          #D4B37B 0%,
          #B49355 45%,
          #A48345 80%,
          #937235 100%
      );
  background-blend-mode: soft-light;
  box-shadow: 
      0 2px 4px rgba(0, 0, 0, 0.1),
      inset 0 1px 3px rgba(255, 255, 255, 0.6);
  transform: rotate(0deg);
}

.piece-shape::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
      linear-gradient(
          155deg,
          rgba(255, 255, 255, 0.7) 0%,
          rgba(255, 245, 225, 0.2) 30%,
          rgba(255, 235, 205, 0.1) 70%,
          rgba(0, 0, 0, 0.08) 100%
      ),
      repeating-linear-gradient(
          65deg,
          transparent 0px,
          transparent 3px,
          rgba(255, 245, 225, 0.15) 3px,
          rgba(255, 245, 225, 0.15) 6px
      );
  clip-path: inherit;
  pointer-events: none;
}

.piece-symbol {
  font-size: 16px;
  font-weight: bold;
  color: #000000;
  text-shadow: 
      0 1px 2px rgba(255, 255, 255, 0.8),
      0 0 10px rgba(255, 255, 255, 0.4);
  margin-top: 12px;
  transform: scaleY(1.3);
  writing-mode: vertical-rl;
  text-orientation: upright;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: none;
}

.piece-shape.w {
  transform: rotate(180deg);
}

.piece-shape.w .piece-symbol {
  transform: scaleY(1.3);
}

.piece-shape.b-promoted {
  background: 
    repeating-linear-gradient(
      -65deg,
      #C87878 0px,
      #C87878 4px,
      #B76868 4px,
      #B76868 8px
    ),
    linear-gradient(
      155deg,
      #D48888 0%,
      #B76868 45%,
      #A75858 80%,
      #964848 100%
    );
  background-blend-mode: soft-light;
}

.piece-shape.w-promoted {
  background: 
    repeating-linear-gradient(
      -65deg,
      #C87878 0px,
      #C87878 4px,
      #B76868 4px,
      #B76868 8px
    ),
    linear-gradient(
      155deg,
      #D48888 0%,
      #B76868 45%,
      #A75858 80%,
      #964848 100%
    );
  background-blend-mode: soft-light;
  transform: rotate(180deg);
}

.piece-shape.w-promoted .piece-symbol {
  transform: scaleY(1.3);
}

.piece-shape:hover {
  filter: brightness(1.1);
}

.shogi-cell:active {
  cursor: grabbing;
}
</style> 