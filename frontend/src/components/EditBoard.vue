<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, computed, watch } from 'vue';
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
    if (piece === piece.toUpperCase() && !piece.startsWith('+') && count > 0) {
      result[piece] = count;
    }
  }
  console.log('計算された先手の持ち駒:', result);
  return result;
});

// 後手の持ち駒を計算
const whitePieces = computed(() => {
  const result: Record<string, number> = {};
  // 小文字の駒（後手）を抽出
  for (const [piece, count] of Object.entries(boardStore.piecesInHand)) {
    if (piece === piece.toLowerCase() && !piece.startsWith('+') && count > 0) {
      result[piece] = count;
    }
  }
  console.log('計算された後手の持ち駒:', result);
  return result;
});

// 各駒の操作回数を追跡するためのマップ
const pieceClickCount = ref<Map<string, number>>(new Map());

// 駒の状態変更を行う関数
const cyclePieceState = (piece: NonNullPieceType): NonNullPieceType => {
  // 初期状態の判定
  const isPromoted = piece.startsWith('+');
  const isGote = isPromoted ? 
    piece.charAt(1) === piece.charAt(1).toLowerCase() : 
    piece === piece.toLowerCase();
  
  // 基本形を取得（成りや向きを除いた駒の種類）
  const baseType = isPromoted ? piece.charAt(1) : piece;
  const baseTypeUpper = baseType.toUpperCase();
  
  // 4つの状態を定義
  const states = [
    baseTypeUpper,                    // 0: 先手の基本形
    `+${baseTypeUpper}`,             // 1: 先手の成駒
    `+${baseTypeUpper.toLowerCase()}`, // 2: 後手の成駒
    baseTypeUpper.toLowerCase()       // 3: 後手の基本形
  ];
  
  // 現在の状態を特定
  let currentStateIndex = 0;
  if (piece === baseTypeUpper) {
    currentStateIndex = 0; // 先手の基本形
  } else if (piece === `+${baseTypeUpper}`) {
    currentStateIndex = 1; // 先手の成駒
  } else if (piece === `+${baseTypeUpper.toLowerCase()}`) {
    currentStateIndex = 2; // 後手の成駒
  } else if (piece === baseTypeUpper.toLowerCase()) {
    currentStateIndex = 3; // 後手の基本形
  }
  
  // 次の状態に進む（4で1周する）
  const nextStateIndex = (currentStateIndex + 1) % 4;
  return states[nextStateIndex] as NonNullPieceType;
};

// 駒台の駒をクリックした時の処理
const handleHandPieceClick = (piece: string) => {
  // 持ち駒の数が0より大きいかチェック
  if (!boardStore.piecesInHand[piece as NonNullPieceType] || 
      boardStore.piecesInHand[piece as NonNullPieceType] <= 0) return;
  
  // 駒を選択状態にする
  selectedHandPiece.value = piece as NonNullPieceType;
  console.log(`持ち駒を選択: ${piece}`);
};

// ドラッグ中の表示用の要素
const dragPreview = ref<HTMLElement | null>(null);
const dragPreviewVisible = ref(false);
const dragPreviewPiece = ref<PieceType | null>(null);
const dragPreviewIsGote = ref(false);
const draggingPiece = ref<DraggingPiece | null>(null);

// ドラッグ開始時にカスタムドラッグプレビューを表示
const showDragPreview = (piece: PieceType, isGote: boolean, event?: DragEvent): void => {
  // ドラッグプレビューの内容を設定
  if (dragPreview.value && event) {
    // 盤上の駒と完全に同じデザインを適用
    const isPiecePromoted = typeof piece === 'string' && piece.startsWith('+');
    
    // クラスを計算
    const pieceClasses = [
      isGote ? 'w' : 'b',
      isGote && isPiecePromoted ? 'w-promoted' : '',
      !isGote && isPiecePromoted ? 'b-promoted' : ''
    ].filter(Boolean).join(' ');
    
    // フルサイズの駒形状を維持するために明示的なスタイルを設定
    dragPreview.value.innerHTML = `
      <div class="piece-container">
        <div class="piece-shape ${pieceClasses}">
          <div class="piece-symbol">${getPieceDisplay(piece)}</div>
        </div>
      </div>
    `;
    
    // 初期位置を設定
    const x = event.clientX - 22.5;
    const y = event.clientY - 22.5;
    
    dragPreview.value.style.display = 'block';
    dragPreview.value.style.left = `${x}px`;
    dragPreview.value.style.top = `${y}px`;
    
    // 値を保存
    dragPreviewPiece.value = piece;
    dragPreviewIsGote.value = isGote;
    dragPreviewVisible.value = true;
  }
};

// ドラッグ終了時にカスタムドラッグプレビューを非表示
const hideDragPreview = (): void => {
  if (dragPreview.value) {
    dragPreview.value.style.display = 'none';
  }
  dragPreviewVisible.value = false;
};

// 全体のドラッグオーバーイベントを監視
const onDocumentDragOver = (event: DragEvent): void => {
  if (dragPreviewVisible.value && dragPreview.value) {
    // カーソル位置に合わせて要素を移動
    const x = event.clientX - 22.5;
    const y = event.clientY - 22.5;
    
    dragPreview.value.style.left = `${x}px`;
    dragPreview.value.style.top = `${y}px`;
  }
};

// 持ち駒のドラッグ開始処理
const onHandPieceDragStart = (event: DragEvent, piece: string) => {
  if (!event.dataTransfer) return;
  
  // 持ち駒の数が0より大きいかチェック
  if (!boardStore.piecesInHand[piece as NonNullPieceType] || 
      boardStore.piecesInHand[piece as NonNullPieceType] <= 0) {
    event.preventDefault();
    return;
  }
  
  // 駒を選択状態にする
  selectedHandPiece.value = piece as NonNullPieceType;
  
  // ドラッグデータをセット
  const data = JSON.stringify({ piece, fromHand: true });
  event.dataTransfer.setData('text/plain', data);
  
  // 後手の駒かどうか判定
  const isGote = piece === piece.toLowerCase();
  
  // カスタムドラッグプレビューを表示
  showDragPreview(piece as NonNullPieceType, isGote, event);
  
  // ドラッグゴーストを透明に
  const canvas = document.createElement('canvas');
  canvas.width = 1;
  canvas.height = 1;
  const ctx = canvas.getContext('2d');
  if (ctx) {
    ctx.clearRect(0, 0, 1, 1);
  }
  document.body.appendChild(canvas);
  
  event.dataTransfer.setDragImage(canvas, 0, 0);
  
  setTimeout(() => {
    document.body.removeChild(canvas);
  }, 100);
  
  event.dataTransfer.effectAllowed = 'move';
};

// ドラッグ開始時のイベントハンドラ
const onDragStart = (event: DragEvent, piece: PieceType, row: number, col: number): void => {
  if (!event.dataTransfer) return;
  
  // 駒の向きの判定
  const isGote = typeof piece === 'string' && (
    (piece === piece.toLowerCase() && !piece.startsWith('+')) || 
    (piece.startsWith('+') && piece[1] === piece[1].toLowerCase())
  );
  
  // デバッグ情報
  console.log('ドラッグ開始時の駒情報:', { 
    piece, 
    row, 
    col,
    isGote
  });
  
  // 駒の情報を保存
  draggingPiece.value = { piece, row, col };
  
  // HTML5ドラッグ&ドロップAPIのデータ設定
  const data = JSON.stringify({ piece, row, col, isGote });
  event.dataTransfer.setData('text/plain', data);
  
  // カスタムドラッグプレビューを表示
  showDragPreview(piece, isGote, event);
  
  // ドラッグゴーストを透明に
  const canvas = document.createElement('canvas');
  canvas.width = 1;
  canvas.height = 1;
  const ctx = canvas.getContext('2d');
  if (ctx) {
    ctx.clearRect(0, 0, 1, 1);
  }
  document.body.appendChild(canvas);
  
  event.dataTransfer.setDragImage(canvas, 0, 0);
  
  setTimeout(() => {
    document.body.removeChild(canvas);
  }, 100);
  
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
  
  // カスタムドラッグプレビューを非表示
  hideDragPreview();
  
  try {
    // dataTransferからデータを取得
    const dataTransferText = event.dataTransfer?.getData('text/plain');
    
    if (dataTransferText) {
      const parsedData = JSON.parse(dataTransferText);
      
      // 持ち駒からのドラッグの場合
      if (parsedData.fromHand) {
        const { piece } = parsedData;
        console.log('持ち駒からドロップ:', { piece, toRow, toCol });
        
        // 移動先に既に駒がある場合の処理
        const targetCell = boardStore.board[toRow][toCol];
        if (targetCell !== null) {
          // 移動先の駒のクリック回数をクリア
          clearPieceClickCount(toRow, toCol);
          
          // 駒が成っている場合は、成っていない状態に戻す
          let baseForm: NonNullPieceType = targetCell as NonNullPieceType;
          
          if (typeof targetCell === 'string' && targetCell.startsWith('+')) {
            const baseChar = targetCell.charAt(1);
            baseForm = baseChar as NonNullPieceType;
          }
          
          // 駒の所有権を反対にして持ち駒に追加
          if (typeof baseForm === 'string') {
            const isUpperCase = baseForm === baseForm.toUpperCase();
            const ownedPiece = isUpperCase ? 
              baseForm.toLowerCase() as NonNullPieceType : 
              baseForm.toUpperCase() as NonNullPieceType;
              
            boardStore.piecesInHand[ownedPiece] = (boardStore.piecesInHand[ownedPiece] || 0) + 1;
          }
        }
        
        // 持ち駒を盤面に配置
        boardStore.board[toRow][toCol] = piece as NonNullPieceType;
        // 持ち駒を減らす
        boardStore.usePieceFromHand(piece as NonNullPieceType);
        boardStore.unsavedChanges = true;
      } else {
        // 盤上の駒からのドラッグの場合
        const { piece, row, col } = parsedData;
        
        console.log('盤上の駒からドロップ:', { piece, row, col, toRow, toCol });
        
        // 同じ場所にドロップした場合は何もしない
        if (row === toRow && col === toCol) {
          return;
        }
        
        // 移動元のクリック回数をクリア
        clearPieceClickCount(row, col);
        // 移動先のクリック回数もクリア
        clearPieceClickCount(toRow, toCol);
        
        // 移動を実行
        boardStore.movePiece({
          from: { row, col },
          to: { row: toRow, col: toCol },
          piece
        });
      }
    } else if (draggingPiece.value) {
      // フォールバック: draggingPiece.valueからの利用
      const { piece, row, col } = draggingPiece.value;
      
      if (piece === null) return;
      
      // 同じ場所にドロップした場合は何もしない
      if (row === toRow && col === toCol) {
        return;
      }
      
      // 移動元のクリック回数をクリア
      clearPieceClickCount(row, col);
      // 移動先のクリック回数もクリア
      clearPieceClickCount(toRow, toCol);
      
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
    selectedHandPiece.value = null;
  }
};

// 右クリックイベントハンドラ（クリック回数もクリア）
const onRightClick = (event: MouseEvent, row: number, col: number): void => {
  event.preventDefault(); // コンテキストメニューを表示しない
  const piece = boardStore.getPieceAt(row, col);
  
  if (piece) {
    // クリック回数をクリア
    clearPieceClickCount(row, col);
    
    // 駒が成っている場合は、成っていない状態に戻す
    let baseForm: NonNullPieceType = piece as NonNullPieceType;
    
    if (typeof piece === 'string' && piece.startsWith('+')) {
      // 成り駒の場合、成っていない駒に戻す
      // "+P" -> "P", "+p" -> "p" のように変換
      const baseChar = piece.charAt(1);
      baseForm = baseChar as NonNullPieceType;
    }
    
    // 駒の所有権を維持したまま持ち駒に追加
    if (typeof baseForm === 'string') {
      // 持ち駒を増やす
      boardStore.piecesInHand[baseForm] = (boardStore.piecesInHand[baseForm] || 0) + 1;
      console.log(`持ち駒に追加: ${baseForm}`, boardStore.piecesInHand);
    }
    
    // 盤面から駒を削除
    boardStore.removePiece(row, col);
    console.log('右クリックで駒を持ち駒に移動しました:', piece);
    boardStore.unsavedChanges = true;
  }
};

// マスをクリックした時の処理
const handleCellClick = (row: number, col: number) => {
  // 持ち駒が選択されている場合
  if (selectedHandPiece.value) {
    const targetCell = boardStore.board[row][col];
    const piece = selectedHandPiece.value;
    
    // 移動先に既に駒がある場合は駒台に追加
    if (targetCell !== null) {
      console.log('移動先に駒があります。駒台に追加します:', targetCell);
      
      // 移動先の駒のクリック回数をクリア
      clearPieceClickCount(row, col);
      
      // 駒が成っている場合は、成っていない状態に戻す
      let baseForm: NonNullPieceType = targetCell as NonNullPieceType;
      
      if (typeof targetCell === 'string' && targetCell.startsWith('+')) {
        // 成り駒の場合、成っていない駒に戻す
        // "+P" -> "P", "+p" -> "p" のように変換
        const baseChar = targetCell.charAt(1);
        baseForm = baseChar as NonNullPieceType;
      }
      
      // 駒の所有権を反対にする（相手の駒として持ち駒に追加）
      if (typeof baseForm === 'string') {
        // 大文字(先手)の駒は小文字(後手)に、小文字の駒は大文字に変換
        const isUpperCase = baseForm === baseForm.toUpperCase();
        const ownedPiece = isUpperCase ? 
          baseForm.toLowerCase() as NonNullPieceType : 
          baseForm.toUpperCase() as NonNullPieceType;
          
        // 持ち駒を増やす
        boardStore.piecesInHand[ownedPiece] = (boardStore.piecesInHand[ownedPiece] || 0) + 1;
        console.log(`持ち駒に追加: ${ownedPiece}`, boardStore.piecesInHand);
      }
    }
    
    // 駒を配置
    boardStore.board[row][col] = piece;
    // 持ち駒を減らす
    boardStore.usePieceFromHand(piece);
    // 選択状態をクリア
    selectedHandPiece.value = null;
    
    console.log(`駒を配置: ${piece} at ${row}-${col}`);
    boardStore.unsavedChanges = true;
  } else {
    // 持ち駒が選択されていない場合は駒の状態変更
    const piece = boardStore.getPieceAt(row, col);
    
    if (piece) {
      console.log('クリックで駒の状態を変更します:', { row, col, piece });
      
      // 駒の位置をキーとして使用
      const positionKey = `${row}-${col}`;
      
      // 現在のクリック回数を取得（初回は0）
      const currentCount = pieceClickCount.value.get(positionKey) || 0;
      
      // クリック回数を増やす（4で1サイクル）
      const newCount = (currentCount + 1) % 4;
      pieceClickCount.value.set(positionKey, newCount);
      
      // 駒の状態を次の状態に変更
      const newPiece = cyclePieceState(piece as NonNullPieceType);
      
      // 盤面を更新
      boardStore.board[row][col] = newPiece;
      boardStore.unsavedChanges = true;
      
      // 操作内容をログ出力
      const operations = ['成る', '向きを変える', '成不成を反転', '向きを戻す'];
      console.log(`操作: ${operations[newCount]} (${piece} → ${newPiece})`);
    }
  }
};

// ダブルクリックイベントハンドラ（無効化）
const onDoubleClick = (row: number, col: number): void => {
  // ダブルクリックイベントを無効化（シングルクリックのみ使用）
  // 何もしない
};

// 駒が移動したときなどに位置キーをクリアする関数
const clearPieceClickCount = (row: number, col: number): void => {
  const positionKey = `${row}-${col}`;
  pieceClickCount.value.delete(positionKey);
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
    if (piece) {
      console.log('長押しで駒を削除します:', { row, col, piece });
      boardStore.removePiece(row, col);
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
  
  // カスタムドラッグプレビュー要素を作成
  const previewElement = document.createElement('div');
  previewElement.className = 'drag-preview';
  previewElement.style.position = 'fixed';
  previewElement.style.zIndex = '9999';
  previewElement.style.pointerEvents = 'none';
  previewElement.style.display = 'none';
  previewElement.style.left = '0';
  previewElement.style.top = '0';
  document.body.appendChild(previewElement);
  dragPreview.value = previewElement;
  
  // 全体のドラッグオーバーイベントを監視
  document.addEventListener('dragover', onDocumentDragOver);
  
  // ドラッグ終了イベントのグローバル監視
  window.addEventListener('dragend', hideDragPreview);
  
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
  window.removeEventListener('dragend', hideDragPreview);
  document.removeEventListener('dragover', onDocumentDragOver);
  
  // カスタムドラッグプレビュー要素を削除
  if (dragPreview.value) {
    document.body.removeChild(dragPreview.value);
  }
});

// ドラッグプレビューの内容を監視して更新
watch([dragPreviewVisible], () => {
  if (!dragPreview.value) return;
  
  if (dragPreviewVisible.value) {
    // ドラッグプレビューを表示
    dragPreview.value.style.display = 'block';
  } else {
    // ドラッグプレビューを非表示
    dragPreview.value.style.display = 'none';
  }
});
</script>

<template>
  <div class="edit-board-container">
    <div class="board-controls">
      <div class="current-side">
        現在: {{ boardStore.currentSide === 'b' ? '先手' : '後手' }}
      </div>
      
      <button @click="toggleSide" class="toggle-side-btn">
        手番切り替え
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
          draggable="true"
          @dragstart="onHandPieceDragStart($event, piece)"
        >
          <div class="piece-shape" :class="{ 'w': true, 'selected': selectedHandPiece === piece }">
            <div class="piece-symbol">{{ getPieceDisplay(piece) }}</div>
            <div class="piece-count" v-if="count > 1">{{ count }}</div>
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
          draggable="true"
          @dragstart="onHandPieceDragStart($event, piece)"
        >
          <div class="piece-shape" :class="{ 'b': true, 'selected': selectedHandPiece === piece }">
            <div class="piece-symbol">{{ getPieceDisplay(piece) }}</div>
            <div class="piece-count" v-if="count > 1">{{ count }}</div>
          </div>
        </div>
      </div>
      
      <!-- 操作説明 -->
      <div class="operation-guide">
        <p>右クリック: 盤上の駒を持ち駒に戻す</p>
        <p>クリック: 駒の状態変更（成る→向き変更→成不成反転→向き戻し）</p>
        <p>持ち駒クリック→マスクリック: 持ち駒を盤上に配置</p>
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

.pieces-label {
  margin-top: 10px;
  font-weight: bold;
  font-size: 16px;
  color: #4A3728;
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
  cursor: pointer;
  margin: 0 2px;
  position: relative;
}

.selected {
  box-shadow: 0 0 5px 2px rgba(255, 215, 0, 0.8);
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
      0 2px 4px rgba(0, 0, 0, 0.2),
      inset 0 1px 3px rgba(255, 255, 255, 0.6);
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
  opacity: 0.95;
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
    0 2px 4px rgba(0, 0, 0, 0.2),
    inset 0 1px 3px rgba(255, 255, 255, 0.6);
}

.piece-shape.b-promoted .piece-symbol {
  transform: scaleY(1.3);
}

.piece-shape.w-promoted {
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
    0 2px 4px rgba(0, 0, 0, 0.2),
    inset 0 1px 3px rgba(255, 255, 255, 0.6);
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

.operation-guide {
  margin-top: 10px;
  font-size: 0.8rem;
  color: #666;
}

.operation-guide p {
  margin: 5px 0;
}

/* ドラッグ中の駒の外観を調整 */
[draggable="true"] {
  user-select: none;
  -webkit-user-drag: element;
}

/* 後手の駒の回転スタイル強化 */
.piece-shape.w {
  transform: rotate(180deg) !important;
}

/* 後手の駒のドラッグ中も向きを維持する */
.piece-shape.w .piece-symbol {
  transform: scaleY(1.3) !important;
  transform-origin: center;
}

/* ドラッグ中のゴースト要素が見えないようにする */
::-webkit-drag, [draggable="true"] {
  -webkit-user-drag: element;
}

/* グローバルスタイル - ドラッグ中の後手の駒の向きを修正 */
:global(.gote-drag-image) {
  transform: rotate(180deg) !important;
}

:global(.gote-drag-image .piece-shape) {
  transform: rotate(180deg) !important;
}

:global(.gote-drag-image .piece-symbol) {
  transform: scaleY(1.3) !important;
}

/* 後手の駒の向きをドラッグ中も維持 */
.w [draggable="true"] {
  transform: rotate(180deg) !important;
}

/* 駒のドラッグ時のゴースト画像スタイル */
.ghost-piece {
  position: absolute;
  z-index: 9999;
  opacity: 0.85;
  pointer-events: none;
  will-change: transform;
  transition: none;
}

/* 成り駒のスタイル */
.piece-shape.b-promoted {
  /* ... existing styles ... */
}

/* ... rest of existing styles ... */

/* ドラッグプレビューのスタイル */
:global(.drag-preview) {
  position: fixed;
  z-index: 9999;
  pointer-events: none;
  display: block;
  width: 45px;
  height: 45px;
  /* translateを使用しないのでwill-changeプロパティは不要 */
}

:global(.drag-preview .piece-container) {
  width: 45px;
  height: 45px;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

:global(.drag-preview .piece-shape) {
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
      0 2px 4px rgba(0, 0, 0, 0.2),
      inset 0 1px 3px rgba(255, 255, 255, 0.6);
  filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.3));
  opacity: 0.95;
  transform: rotate(0deg);
}

:global(.drag-preview .piece-shape::before) {
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

:global(.drag-preview .piece-symbol) {
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

:global(.drag-preview .piece-shape.w) {
  transform: rotate(180deg) !important;
}

:global(.drag-preview .piece-shape.w .piece-symbol) {
  transform: scaleY(1.3) !important;
}

:global(.drag-preview .piece-shape.b-promoted) {
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
    0 2px 4px rgba(0, 0, 0, 0.2),
    inset 0 1px 3px rgba(255, 255, 255, 0.6);
}

:global(.drag-preview .piece-shape.w-promoted) {
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
    0 2px 4px rgba(0, 0, 0, 0.2),
    inset 0 1px 3px rgba(255, 255, 255, 0.6);
  transform: rotate(180deg);
}

:global(.drag-preview .piece-shape.w-promoted .piece-symbol) {
  transform: scaleY(1.3);
}
</style> 