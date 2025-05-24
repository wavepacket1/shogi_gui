<template>
    <div class="wrapper">
        <div class="shogi-container">
            <div class="board-column">
                <div class="game-info">
                    <div class="control-panel">
                        <button @click="startGame">対局開始</button> 
                        <button @click="entering_king_declaration">入玉宣言</button>
                        <ResignButton
                            v-if="boardStore.game?.id"
                            :game-id="boardStore.game.id"
                            :disabled="!canResign"
                            @resign-complete="handleResignComplete"
                        />
                    </div>
                    <div class="info">手数: {{ getStepNumber }} &nbsp;|&nbsp; 手番: {{ getOwner }}</div>
                    <div>{{ getGameState }}</div>
                </div>

                <div class="board-area">
                    <PiecesInHand 
                        class="pieces-in-hand-top" 
                        :pieces="piecesInHandW"
                        :isGote="true"
                        :selectedPiece="selectedHandPiece"
                        @piece-click="handlePieceClick"
                    />

                    <ShogiBoardGrid 
                        :board="boardStore.shogiData.board"
                        :selectedCell="boardStore.selectedCell"
                        :activePlayer="boardStore.activePlayer || 'b'"
                        @cell-click="handleCellClick"
                    />

                    <PiecesInHand 
                        class="pieces-in-hand-bottom" 
                        :pieces="piecesInHandB"
                        :isGote="false"
                        :selectedPiece="selectedHandPiece"
                        @piece-click="handlePieceClick"
                    />
                </div>
            </div>
            
            <!-- 棋譜パネルを将棋盤の右側に配置 -->
            <div v-if="boardStore.game" class="move-history-container">
                <MoveHistoryPanel 
                    :game-id="boardStore.game.id" 
                    :mode="currentMode"
                />
            </div>
        </div>

        <PromotionModal 
            :is-open="showPromotionModal"
            @promote="handlePromotion"
        />
    </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, computed } from 'vue';
import { useBoardStore } from '@/store';
import { useModeStore } from '@/store/mode';
import PiecesInHand from './PiecesInHand.vue';
import ShogiBoardGrid from './ShogiBoardGrid.vue';
import PromotionModal from './PromotionModal.vue';
import MoveHistoryPanel from './MoveHistoryPanel.vue';
import ResignButton from '@/components/game/ResignButton.vue';

export default defineComponent({
    name: 'ShogiBoard',
    components: {
        PiecesInHand,
        ShogiBoardGrid,
        PromotionModal,
        MoveHistoryPanel,
        ResignButton,
    },
    setup() {
        const boardStore = useBoardStore();
        const modeStore = useModeStore();
        const isLoading = ref(true);
        const errorMessage = ref('');
        const showPromotionModal = ref(false);
        const pendingMove = ref<{x: number, y: number} | null>(null);
        const selectedHandPiece = ref<string | undefined>(undefined);

        const currentMode = computed(() => {
            // GameModeをstringに変換
            return modeStore.currentMode.toLowerCase() as 'play' | 'edit' | 'study';
        });
        const getStepNumber = computed(() => boardStore.stepNumber);

        const getOwner = computed(() => (boardStore.activePlayer === 'b' ? '先手' : '後手'));

        const getGameState = computed(() => {
            // ゲームが存在しない場合は空文字を返す
            if (!boardStore.game) {
                return '';
            }

            // ゲームが終了している場合は投了による勝敗を表示
            if (boardStore.game.status === 'finished') {
                // activePlayerが先手('b')の場合は後手の勝ち、後手('w')の場合は先手の勝ち
                return boardStore.activePlayer === 'b' ? '後手の勝ち（先手投了）' : '先手の勝ち（後手投了）';
            }

            // その他の勝敗判定
            if (boardStore.is_checkmate) {
                return boardStore.activePlayer === 'b' ? '後手勝ち' : '先手勝ち';
            }
            if(boardStore.is_repetition_check){
                return boardStore.activePlayer === 'b' ? '連続王手の千日手で先手勝ち' : '連続王手の千日手で後手勝ち';
            }
            if (boardStore.is_repetition) {
                return '千日手';
            }
            if (boardStore.is_check_entering_king === true) {
                return boardStore.activePlayer === 'b' ? '先手入玉宣言勝ち' : '後手入玉宣言勝ち';
            }
            else if (boardStore.is_check_entering_king === false) {
                return boardStore.activePlayer === 'b' ? '入玉失敗で後手勝ち' : '入玉失敗で先手勝ち';
            }
            return '';
        });

        const initializeGame = async () => {
            try {
                isLoading.value = true;
                await boardStore.initializeGameFromUrl();  // URLまたは新規ゲームを初期化
            } catch (error) {
                errorMessage.value = 'ゲームの初期化に失敗しました';
                console.error('Error initializing game:', error);
            } finally {
                isLoading.value = false;
            }
        };

        const canPromote = (fromY: number, toY: number, piece: any) => {
            // 成れる条件をチェック
            const isInPromotionZone = (
                (piece.owner === 'b' && (toY <= 2 || fromY <= 2)) ||
                (piece.owner === 'w' && (toY >= 6 || fromY >= 6))
            );
            
            // 既に成っている駒は除外
            if (piece.promoted) return false;

            // 成れない駒（金将、玉将）は除外
            const cantPromotePieces = ['G', 'K'];
            if (cantPromotePieces.includes(piece.piece_type.toUpperCase())) return false;

            // その手が有効手かどうかをチェック
            const isLegalMove = isValidMove(fromY, toY, piece);

            return isInPromotionZone && isLegalMove;
        };

        // 有効手かどうかをチェックする関数
        const isValidMove = (fromY: number, toY: number, piece: any): boolean => {
            const pieceType = piece.piece_type.toUpperCase();
            const owner = piece.owner;

            // 各駒の移動可能範囲をチェック
            switch (pieceType) {
                case 'P': // 歩
                    return owner === 'b' ? fromY - toY === 1 : toY - fromY === 1;
                case 'L': // 香車
                    return owner === 'b' ? toY < fromY : toY > fromY;
                case 'N': // 桂馬
                    if (owner === 'b') {
                        return toY >= 2; // 2段目より手前には進めない
                    } else {
                        return toY <= 6; // 8段目より奥には進めない
                    }
                case 'S': // 銀
                case 'G': // 金
                case 'B': // 角
                case 'R': // 飛車
                    return true; // これらの駒は成り判定のみで十分
                default:
                    return false;
            }
        };

        const handlePieceClick = (piece: string) => {
            // 先手の場合は大文字の駒のみ、後手の場合は小文字の駒のみ選択可能
            const isUpperCase = piece === piece.toUpperCase();
            if ((boardStore.activePlayer === 'b' && !isUpperCase) || 
                (boardStore.activePlayer === 'w' && isUpperCase)) {
                console.log('Invalid piece selection');
                return;
            }
            
            // 既に選択されている駒をクリックした場合は選択解除
            if (selectedHandPiece.value === piece) {
                selectedHandPiece.value = undefined;
                boardStore.SetCell(null);
                return;
            }

            selectedHandPiece.value = piece;
            boardStore.SetCell(null);
        };

        const handleCellClick = async (x: number, y: number) => {
            try {
                if (!boardStore.game?.id || !boardStore.board_id) {
                    await initializeGame();
                    return;
                }

                // 持ち駒を打つ場合
                if (selectedHandPiece.value) {
                    if (boardStore.shogiData.board[y][x]) {
                        console.log('Cannot drop on occupied square');
                        return;
                    }

                    await boardStore.dropPiece(
                        boardStore.game.id,
                        boardStore.board_id,
                        selectedHandPiece.value,
                        x,
                        y
                    );
                    selectedHandPiece.value = undefined;
                    return;
                }

                const clickedCell = { x, y };
                const currentPiece = boardStore.shogiData.board[y][x];
                
                if (boardStore.selectedCell.x === null || boardStore.selectedCell.y === null) {
                    if (currentPiece && currentPiece.owner === boardStore.activePlayer) {
                        boardStore.SetCell(clickedCell);
                    }
                    return;
                }

                if (boardStore.selectedCell.x === x && boardStore.selectedCell.y === y) {
                    boardStore.SetCell(null);
                    return;
                }

                const selectedPiece = boardStore.shogiData.board[boardStore.selectedCell.y][boardStore.selectedCell.x];
                if (canPromote(boardStore.selectedCell.y, y, selectedPiece)) {
                    showPromotionModal.value = true;
                    pendingMove.value = { x, y };
                    return;
                }

                await boardStore.movePiece(boardStore.game.id, boardStore.board_id, x, y, false);
                boardStore.SetCell(null);

            } catch (error) {
                console.error('Error in handleCellClick:', error);
                boardStore.SetCell(null);
                selectedHandPiece.value = undefined;
            }
        };

        const handlePromotion = async (shouldPromote: boolean) => {
            if (pendingMove.value && boardStore.game?.id && boardStore.board_id) {
                await boardStore.movePiece(
                    boardStore.game.id,
                    boardStore.board_id,
                    pendingMove.value.x,
                    pendingMove.value.y,
                    shouldPromote
                );
                boardStore.SetCell(null);
            }
            showPromotionModal.value = false;
            pendingMove.value = null;
        };

        const entering_king_declaration = async () => {
            if(!boardStore.game || boardStore.board_id === null) {
                console.error('boardStore.game または boardStore.board_idがnullです');
                return;
            }
            try {
                await boardStore.enteringKingDeclaration(
                    boardStore.game!.id, 
                    boardStore.board_id!,
                );
            } catch (error) {
                console.error('Error in entering_king_declaration:', error);
            }
        };

        const startGame = async () => {
            await boardStore.createGame();
        };

        // 投了ボタンの表示・有効化条件
        const canResign = computed(() => {
            return !!boardStore.game?.id && boardStore.game.status === 'active';
        });

        // 投了完了時の処理
        const handleResignComplete = async () => {
            console.log('投了完了。ゲーム状態を更新します...');
            if (boardStore.game?.id) {
                try {
                    await boardStore.fetchBoardHistories(boardStore.game.id, boardStore.currentBranch, false);
                } catch (error) {
                    console.error("ゲーム状態の更新に失敗:", error);
                }
            }
        };

        // 駒の順序を定義
        const PIECE_ORDER = ['P', 'N', 'L', 'S', 'G', 'B', 'R'];

        onMounted(async () => {
            await initializeGame();
        });

        return {
            boardStore,
            piecesInHandB: computed(() => {
                const pieces = boardStore.shogiData?.piecesInHand || {};
                const result: { [key: string]: number } = {};
                // PIECE_ORDERに従って順番に処理
                PIECE_ORDER.forEach(piece => {
                    const count = pieces[piece];
                    if (count) {
                        result[piece] = count;
                    }
                });
                return result;
            }),
            piecesInHandW: computed(() => {
                const pieces = boardStore.shogiData?.piecesInHand || {};
                const result: { [key: string]: number } = {};
                // PIECE_ORDERに従って順番に処理（小文字で検索）
                PIECE_ORDER.forEach(piece => {
                    const lowerPiece = piece.toLowerCase();
                    const count = pieces[lowerPiece];
                    if (count) {
                        result[lowerPiece] = count;
                    }
                });
                return result;
            }),
            isLoading,
            errorMessage,
            currentMode,
            getStepNumber,
            handleCellClick,
            getOwner,
            getGameState,
            initializeGame,
            showPromotionModal,
            handlePromotion,
            handlePieceClick,
            selectedHandPiece,
            entering_king_declaration,
            startGame,
            canResign,
            handleResignComplete,
        };
    },
});
</script>

<style scoped>
.wrapper {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
    min-height: 100vh;
    position: relative;
    padding: 20px 0;
}

/* オプション: キャラクター用スペース */
.wrapper::before {
    content: "";
    position: absolute;
    right: 5%;
    bottom: 5%;
    width: 150px;
    height: 300px;
    background-size: contain;
    background-repeat: no-repeat;
    background-position: bottom right;
    /* キャラクター画像があれば以下のようにURL指定できます */
    /* background-image: url('/path/to/character.png'); */
    opacity: 0.9;
    pointer-events: none;
    z-index: 1;
}

.shogi-container {
    display: flex;
    flex-direction: row;
    align-items: flex-start;
    justify-content: flex-start;
    gap: 30px;
    flex-wrap: wrap;
    width: 100%;
    max-width: 1200px;
    margin: 0 auto;
    padding: 0 15px;
    position: relative;
    z-index: 2;
}

.board-column {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
    max-width: 500px;
    flex-shrink: 0;
    background: rgba(30, 30, 60, 0.9);
    border-radius: 12px;
    box-shadow: 
        0 8px 16px rgba(0,0,0,0.3),
        0 0 20px rgba(138, 43, 226, 0.2),
        inset 0 1px 0 rgba(255, 255, 255, 0.1);
    padding: 20px;
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(15px);
}

.board-area {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
}

.game-info {
    text-align: center;
    margin-bottom: 15px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    align-items: center;
    width: 100%;
}

.pieces-in-hand-top {
    order: 0;
    width: 100%;
    display: flex;
    justify-content: center;
    flex-wrap: wrap;
}

.pieces-in-hand-bottom {
    order: 2;
    width: 100%;
    display: flex;
    justify-content: center;
    flex-wrap: wrap;
}

.control-panel {
    display: flex;
    flex-direction: row;
    gap: 8px;
    align-items: center;
    flex-wrap: wrap;
    justify-content: center;
    width: 100%;
    padding: 5px 0;
}

.game-info button, .game-info :deep(button) {
    padding: 8px 16px;
    border: none;
    border-radius: 8px;
    background: linear-gradient(145deg, #4A90E2, #357ABD);
    color: white;
    cursor: pointer;
    min-width: 90px;
    font-size: 14px;
    text-align: center;
    box-shadow: 
        0 4px 8px rgba(0,0,0,0.2),
        0 0 15px rgba(74, 144, 226, 0.3);
    transition: all 0.3s ease;
    font-weight: 500;
    text-shadow: 0 1px 2px rgba(0,0,0,0.3);
}

.game-info button:hover, .game-info :deep(button):hover {
    background: linear-gradient(145deg, #357ABD, #2E6BA8);
    transform: translateY(-2px);
    box-shadow: 
        0 6px 12px rgba(0,0,0,0.3),
        0 0 20px rgba(74, 144, 226, 0.5);
}

.info {
    font-size: 14px;
    text-align: left;
    color: #E8E8FF;
    font-weight: 500;
    background: rgba(40, 40, 80, 0.6);
    padding: 6px 12px;
    border-radius: 6px;
    text-shadow: 0 0 5px rgba(255, 255, 255, 0.3);
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
}

/* 履歴パネル用のスタイル */
.move-history-container {
    flex: 0 0 auto;
    width: 280px;
    height: 550px;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    align-self: flex-start;
    margin-top: 75px; /* game-infoの高さに合わせる */
    background: rgba(30, 30, 60, 0.9);
    border-radius: 12px;
    box-shadow: 
        0 8px 16px rgba(0,0,0,0.3),
        0 0 20px rgba(138, 43, 226, 0.2),
        inset 0 1px 0 rgba(255, 255, 255, 0.1);
    border: 1px solid rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(15px);
}

/* MoveHistoryPanelに影響を与えるスタイルを深い選択子で追加 */
.move-history-container :deep(.move-history-panel) {
    width: 100%;
    height: 100%;
    overflow: hidden;
    border: none;
    box-shadow: none;
}

.move-history-container :deep(.panel-header) {
    padding: 6px 10px;
}

.move-history-container :deep(.move-notation) {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.move-history-container :deep(.moves-container) {
    padding: 6px;
}

.move-history-container :deep(.move-item) {
    padding: 4px 6px;
    margin-bottom: 3px;
}

/* レスポンシブ対応 */
@media (max-width: 992px) {
    .shogi-container {
        justify-content: center;
        gap: 20px;
        padding: 0 10px;
    }
    
    .board-column {
        max-width: 480px;
        padding: 15px;
    }
    
    .move-history-container {
        width: 300px;
        margin-top: 20px;
        height: 400px;
    }
}

@media (max-width: 768px) {
    .shogi-container {
        flex-direction: column;
        align-items: center;
        gap: 15px;
        padding: 0 5px;
    }
    
    .board-column {
        max-width: 100%;
        width: 100%;
        padding: 12px;
        margin: 0;
    }
    
    .board-area {
        max-width: 100%;
        width: 100%;
    }
    
    .move-history-container {
        max-width: 100%;
        min-width: unset;
        width: 100%;
        height: 280px;
        margin-top: 15px;
    }
    
    .game-info {
        margin-bottom: 12px;
    }
    
    .game-info button {
        font-size: 12px;
        padding: 6px 12px;
        min-width: 80px;
        min-height: 44px; /* タッチフレンドリー */
    }
    
    .control-panel {
        gap: 6px;
    }
    
    /* 将棋盤のサイズ調整 */
    .board-area :deep(.shogi-board) {
        max-width: 100%;
        width: 100%;
        box-sizing: border-box;
    }
    
    /* 駒台のレスポンシブ調整 */
    .pieces-in-hand-top,
    .pieces-in-hand-bottom {
        padding: 8px 0;
    }
    
    /* 情報表示の調整 */
    .info {
        font-size: 13px;
        padding: 5px 10px;
        text-align: center;
    }
}

@media (max-width: 600px) {
    .shogi-container {
        gap: 10px;
        padding: 0;
    }
    
    .board-column {
        padding: 10px;
        border-radius: 8px;
    }
    
    .game-info {
        margin-bottom: 10px;
    }
    
    .control-panel {
        flex-direction: column;
        gap: 6px;
        width: 100%;
    }
    
    .game-info button {
        width: 100%;
        margin: 0;
        font-size: 11px;
        padding: 8px 12px;
        min-height: 44px; /* タッチフレンドリー */
    }
    
    .move-history-container {
        height: 300px;
        border-radius: 8px;
    }
    
    /* 駒台のモバイル最適化 */
    .pieces-in-hand-top,
    .pieces-in-hand-bottom {
        padding: 6px 0;
        min-height: 50px;
        align-items: center;
    }
    
    /* 将棋盤のモバイル最適化 */
    .board-area :deep(.shogi-board) {
        border-width: 2px;
        border-radius: 4px;
    }
    
    .board-area :deep(.cell) {
        min-height: 30px; /* タッチしやすいサイズ */
        font-size: 14px;
    }
    
    .board-area :deep(.piece) {
        font-size: 12px;
        font-weight: bold;
    }
}

@media (max-width: 480px) {
    .wrapper {
        padding: 5px;
    }
    
    .shogi-container {
        gap: 8px;
        padding: 0;
    }
    
    .board-column {
        padding: 8px;
        border-radius: 6px;
    }
    
    .game-info {
        margin-bottom: 8px;
    }
    
    .control-panel {
        gap: 4px;
    }
    
    .game-info button {
        font-size: 10px;
        padding: 10px 8px;
        min-height: 44px; /* アクセシビリティガイドライン準拠 */
        border-radius: 6px;
    }
    
    .info {
        font-size: 12px;
        padding: 4px 8px;
    }
    
    .move-history-container {
        height: 300px;
        margin-top: 10px;
    }
    
    /* 極小画面での将棋盤最適化 */
    .board-area :deep(.shogi-board) {
        border-width: 1px;
        background-size: 11.11% 11.11%; /* 9x9グリッドに最適化 */
    }
    
    .board-area :deep(.cell) {
        min-height: 28px;
        font-size: 12px;
        border-width: 0.5px;
    }
    
    .board-area :deep(.piece) {
        font-size: 10px;
        line-height: 1.2;
    }
    
    /* 駒台の極小画面対応 */
    .pieces-in-hand-top,
    .pieces-in-hand-bottom {
        padding: 4px 0;
        min-height: 44px;
        overflow-x: auto;
        scrollbar-width: none; /* Firefox */
    }
    
    .pieces-in-hand-top::-webkit-scrollbar,
    .pieces-in-hand-bottom::-webkit-scrollbar {
        display: none; /* Chrome, Safari */
    }
}

@media (max-width: 360px) {
    .board-column {
        padding: 6px;
    }
    
    .game-info button {
        font-size: 9px;
        padding: 8px 6px;
        min-height: 44px; /* タッチフレンドリー */
    }
    
    .info {
        font-size: 11px;
        padding: 3px 6px;
    }
    
    .move-history-container {
        height: 250px;
    }
    
    /* 超小画面での将棋盤調整 */
    .board-area :deep(.cell) {
        min-height: 25px;
        font-size: 11px;
    }
    
    .board-area :deep(.piece) {
        font-size: 9px;
    }
}

/* ランドスケープモード対応 */
@media (max-width: 768px) and (orientation: landscape) {
    .shogi-container {
        flex-direction: row;
        justify-content: center;
        gap: 15px;
        max-height: 100vh;
        overflow-y: auto;
    }
    
    .board-column {
        max-width: 400px;
        flex: 0 0 auto;
    }
    
    .move-history-container {
        width: 250px;
        height: 100%;
        max-height: 350px;
        margin-top: 0;
    }
    
    .game-info {
        margin-bottom: 8px;
    }
    
    .control-panel {
        flex-direction: row;
        flex-wrap: wrap;
        gap: 4px;
    }
    
    .game-info button {
        flex: 1;
        min-width: unset;
        font-size: 10px;
    }
}

/* 高解像度画面対応 */
@media (min-width: 1200px) {
    .shogi-container {
        max-width: 1400px;
        gap: 40px;
    }
    
    .board-column {
        max-width: 550px;
    }
    
    .move-history-container {
        width: 300px;
        height: 450px;
    }
}

/* タッチデバイス対応 */
@media (hover: none) and (pointer: coarse) {
    .board-area :deep(.cell) {
        min-height: 35px; /* タッチしやすいサイズ */
    }
    
    .game-info button {
        min-height: 44px; /* タッチターゲットサイズ */
        padding: 12px 16px;
    }
    
    .board-area :deep(.cell:hover) {
        background-color: rgba(219, 186, 138, 0.6); /* タッチ時のフィードバック強化 */
    }
}

/* プリント時の調整 */
@media print {
    .wrapper {
        background: none;
    }
    
    .control-panel {
        display: none;
    }
    
    .move-history-container {
        page-break-inside: avoid;
    }
}

/* 将棋盤のスタイル調整 */
.board-area :deep(.shogi-board) {
    border: 3px solid #855a3d;
    box-shadow: 0 6px 20px rgba(79, 55, 30, 0.25);
    background-color: #e8d0a9;
    background-image: 
        linear-gradient(90deg, rgba(188, 157, 113, 0.12) 1px, transparent 1px),
        linear-gradient(rgba(188, 157, 113, 0.12) 1px, transparent 1px);
    background-size: 10% 10%;
    padding: 2px;
    border-radius: 3px;
}

.board-area :deep(.cell) {
    background-color: #e8d0a9;
    border: 1px solid rgba(150, 120, 90, 0.25);
    box-sizing: border-box;
    transition: all 0.15s ease;
    box-shadow: inset 0 0 1px rgba(120, 100, 70, 0.1);
}

.board-area :deep(.cell.selected) {
    background-color: rgba(219, 172, 96, 0.5) !important;
    box-shadow: inset 0 0 5px rgba(180, 130, 70, 0.5) !important;
}

.board-area :deep(.cell:hover) {
    background-color: rgba(219, 186, 138, 0.4);
}

/* 駒自体のスタイル */
.board-area :deep(.piece) {
    color: #2d1e0f;
    text-shadow: 0 1px 1px rgba(255, 245, 225, 0.7);
    font-weight: bold;
}
</style>
