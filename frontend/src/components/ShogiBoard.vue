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
                <MoveHistoryPanel :game-id="boardStore.game.id" />
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
        const isLoading = ref(true);
        const errorMessage = ref('');
        const showPromotionModal = ref(false);
        const pendingMove = ref<{x: number, y: number} | null>(null);
        const selectedHandPiece = ref<string | undefined>(undefined);

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
                await boardStore.createGame();  // ゲームを作成
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
    background-color: #f7f3e9; /* 和紙風の色 */
    background-image: url('data:image/svg+xml;utf8,<svg width="100" height="100" viewBox="0 0 100 100" xmlns="http://www.w3.org/2000/svg"><rect width="100" height="100" fill="none"/><path d="M0 0L100 100M100 0L0 100" stroke="%23e6dfd2" stroke-width="0.5"/></svg>');
    background-size: 20px 20px;
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
    background-color: #fcf8f0;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(79, 55, 30, 0.15);
    padding: 15px;
    border: 1px solid rgba(188, 166, 129, 0.3);
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
    padding: 6px 12px;
    border: none;
    border-radius: 4px;
    background: linear-gradient(to bottom, #b0856c, #8c6954);
    color: #fff;
    cursor: pointer;
    min-width: 80px;
    font-size: 14px;
    text-align: center;
    box-shadow: 0 2px 4px rgba(79, 55, 30, 0.2);
    transition: all 0.2s ease;
}

.game-info button:hover, .game-info :deep(button):hover {
    background: linear-gradient(to bottom, #c49580, #9d7762);
    transform: translateY(-1px);
    box-shadow: 0 3px 6px rgba(79, 55, 30, 0.25);
}

.info {
    font-size: 14px;
    text-align: left;
    color: #5a4534;
    font-weight: 500;
    background-color: rgba(255, 255, 255, 0.6);
    padding: 4px 8px;
    border-radius: 4px;
}

/* 履歴パネル用のスタイル */
.move-history-container {
    flex: 0 0 auto;
    width: 280px;
    height: 400px;
    display: flex;
    flex-direction: column;
    overflow: hidden;
    align-self: flex-start;
    margin-top: 75px; /* game-infoの高さに合わせる */
    background-color: #fcf8f0;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(79, 55, 30, 0.15);
    border: 1px solid rgba(188, 166, 129, 0.3);
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
    }
    
    .move-history-container {
        width: 320px;
        margin-top: 20px;
    }
}

@media (max-width: 768px) {
    .shogi-container {
        flex-direction: column;
        align-items: center;
    }
    
    .board-column, .board-area {
        max-width: 100%;
    }
    
    .move-history-container {
        max-width: 100%;
        min-width: unset;
        width: 100%;
        height: 300px;
        margin-top: 20px;
    }
    
    .game-info button {
        font-size: 12px;
        padding: 5px 10px;
    }
}

@media (max-width: 480px) {
    .control-panel {
        flex-direction: column;
        gap: 5px;
    }
    
    .game-info button {
        width: 100%;
        margin: 2px 0;
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
