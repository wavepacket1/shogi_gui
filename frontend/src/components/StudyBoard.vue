<template>
    <div class="wrapper">
        <div class="shogi-container">
            <div class="board-column">
                <!-- 検討モード用の情報表示 -->
                <div class="game-info">
                    <div class="study-controls">
                        <button @click="copyPositionToClipboard" class="copy-position-btn">
                            局面コピー
                        </button>
                    </div>
                    <div class="info">手数: {{ getStepNumber }} &nbsp;|&nbsp; 手番: {{ getOwner }}</div>
                    <div class="study-status">{{ studyStatus }}</div>
                </div>

                <div class="board-area">
                    <PiecesInHand 
                        class="pieces-in-hand-top" 
                        :pieces="piecesInHandW"
                        :isGote="true"
                        :selectedPiece="selectedHandPiece"
                        @piece-click="handlePieceClick"
                    />

                                        <ShogiBoardGrid                         :board="boardStore.shogiData.board"                        :selectedCell="boardStore.selectedCell"                        :activePlayer="boardStore.activePlayer || 'b'"                        @cell-click="handleCellClick"                    />

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
                    mode="study"
                    :allow-edit="true"
                    :show-comments="true"
                />
            </div>
        </div>

        <PromotionModal 
            :is-open="showPromotionModal"
            @promote="handlePromotion"
        />

        <!-- 検討モード専用の警告・通知 -->
        <div v-if="moveError" class="move-error-toast">
            {{ moveError }}
        </div>
    </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, computed } from 'vue';
import { useBoardStore } from '@/store';
import { useStudyModeStore } from '@/stores/studyMode';
import PiecesInHand from './PiecesInHand.vue';
import ShogiBoardGrid from './ShogiBoardGrid.vue';
import PromotionModal from './PromotionModal.vue';
import MoveHistoryPanel from './MoveHistoryPanel.vue';

export default defineComponent({
    name: 'StudyBoard',
    components: {
        PiecesInHand,
        ShogiBoardGrid,
        PromotionModal,
        MoveHistoryPanel,
    },
    setup() {
        const boardStore = useBoardStore();
        const studyStore = useStudyModeStore();
        const isLoading = ref(true);
        const errorMessage = ref('');
        const showPromotionModal = ref(false);
        const pendingMove = ref<{x: number, y: number} | null>(null);
        const selectedHandPiece = ref<string | undefined>(undefined);
        const moveError = ref<string | null>(null);

        const getStepNumber = computed(() => boardStore.stepNumber);
        const getOwner = computed(() => (boardStore.activePlayer === 'b' ? '先手' : '後手'));

        // 検討モード用のステータス表示
        const studyStatus = computed(() => {
            if (!boardStore.game) return '';
            
            // 検討モードでは詰み・千日手判定を緩和
            if (boardStore.is_check_entering_king === true) {
                return boardStore.activePlayer === 'b' ? '先手入玉宣言勝ち' : '後手入玉宣言勝ち';
            }
            if (boardStore.is_check_entering_king === false) {
                return boardStore.activePlayer === 'b' ? '入玉失敗で後手勝ち' : '入玉失敗で先手勝ち';
            }
            
            return '検討中...';
        });

        const initializeGame = async () => {
            try {
                isLoading.value = true;
                await boardStore.createGame();
            } catch (error) {
                errorMessage.value = 'ゲームの初期化に失敗しました';
                console.error('Error initializing game:', error);
            } finally {
                isLoading.value = false;
            }
        };

        // 合法手チェック用のエラー表示
        const showMoveError = (message: string) => {
            moveError.value = message;
            setTimeout(() => {
                moveError.value = null;
            }, 3000);
        };

        // 検討モード用の合法手チェック
        const validateMoveForStudy = async (from: {x: number, y: number}, to: {x: number, y: number}): Promise<boolean> => {
            try {
                // TODO: StudyModeStoreのvalidateMoveメソッドを実装後に使用
                // return await studyStore.validateMove(from, to);
                
                // 暫定的に基本的なチェックのみ
                const fromPiece = boardStore.shogiData.board[from.y][from.x];
                if (!fromPiece) return false;
                
                // 自分の駒かチェック
                if (fromPiece.owner !== boardStore.activePlayer) return false;
                
                return true;
            } catch (error) {
                console.error('合法手チェックエラー:', error);
                return false;
            }
        };

        // 駒打ちの合法性チェック
        const validateDropForStudy = async (piece: string, to: {x: number, y: number}): Promise<boolean> => {
            try {
                // TODO: StudyModeStoreのvalidateDropメソッドを実装後に使用
                // return await studyStore.validateDrop(piece, to);
                
                // 暫定的に基本的なチェックのみ
                return !boardStore.shogiData.board[to.y][to.x]; // 空いているマスのみ
            } catch (error) {
                console.error('駒打ちチェックエラー:', error);
                return false;
            }
        };

        const handlePieceClick = (piece: string) => {
            // 検討モードでは手番に関係なく駒を選択可能
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
                        showMoveError('すでに駒が配置されています');
                        return;
                    }

                    // 検討モード用の駒打ちチェック
                    const isValidDrop = await validateDropForStudy(selectedHandPiece.value, {x, y});
                    if (!isValidDrop) {
                        showMoveError('この場所には駒を打てません');
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
                    if (currentPiece) {
                        boardStore.SetCell(clickedCell);
                    }
                    return;
                }

                if (boardStore.selectedCell.x === x && boardStore.selectedCell.y === y) {
                    boardStore.SetCell(null);
                    return;
                }

                // 検討モード用の合法手チェック
                const isValidMove = await validateMoveForStudy(
                    {x: boardStore.selectedCell.x, y: boardStore.selectedCell.y}, 
                    {x, y}
                );
                if (!isValidMove) {
                    showMoveError('この手は指せません');
                    return;
                }

                const selectedPiece = boardStore.shogiData.board[boardStore.selectedCell.y][boardStore.selectedCell.x];
                if (canPromote(boardStore.selectedCell.y, y, selectedPiece)) {
                    showPromotionModal.value = true;
                    pendingMove.value = { x, y };
                    return;
                }

                await boardStore.movePiece(boardStore.game.id, boardStore.board_id, x, y, false);
            } catch (error) {
                console.error('Error handling cell click:', error);
                showMoveError('操作中にエラーが発生しました');
            }
        };

        const canPromote = (fromY: number, toY: number, piece: any): boolean => {
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

        const handlePromotion = async (promote: boolean) => {
            if (pendingMove.value && boardStore.game?.id && boardStore.board_id) {
                await boardStore.movePiece(
                    boardStore.game.id,
                    boardStore.board_id,
                    pendingMove.value.x,
                    pendingMove.value.y,
                    promote
                );
            }
            showPromotionModal.value = false;
            pendingMove.value = null;
        };

        // 局面コピー機能
        const copyPositionToClipboard = async () => {
            try {
                // TODO: SFEN形式での局面コピー機能を実装
                const sfen = boardStore.shogiData?.sfen || '現在の局面';
                await navigator.clipboard.writeText(sfen);
                
                // 成功通知（簡易版）
                const tempMessage = moveError.value;
                moveError.value = '局面をクリップボードにコピーしました';
                setTimeout(() => {
                    moveError.value = tempMessage;
                }, 2000);
            } catch (error) {
                console.error('局面コピーエラー:', error);
                showMoveError('局面のコピーに失敗しました');
            }
        };

        // 駒の順序を定義
        const PIECE_ORDER = ['P', 'N', 'L', 'S', 'G', 'B', 'R'];

        onMounted(async () => {
            await initializeGame();
        });

        return {
            boardStore,
            studyStore,
            piecesInHandB: computed(() => {
                const pieces = boardStore.shogiData?.piecesInHand || {};
                const result: { [key: string]: number } = {};
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
            getOwner,
            studyStatus,
            handleCellClick,
            handlePieceClick,
            handlePromotion,
            copyPositionToClipboard,
            initializeGame,
            showPromotionModal,
            selectedHandPiece,
            moveError,
        };
    },
});
</script>

<style scoped>
.wrapper {    display: flex;    flex-direction: column;    align-items: center;    padding: 20px;    /* 宇宙テーマ背景を継承 */    background: transparent;    min-height: 100vh;    font-family: 'Noto Sans JP', sans-serif;}

.shogi-container {
    display: flex;
    gap: 30px;
    max-width: 1400px;
    width: 100%;
}

.board-column {
    flex: 0 0 auto;
}

.game-info {
    text-align: center;
    margin-bottom: 20px;
    background: rgba(30, 30, 60, 0.95);
    padding: 15px;
    border-radius: 8px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.study-controls {
    margin-bottom: 10px;
}

.copy-position-btn {
    background-color: #4CAF50;
    color: white;
    border: none;
    padding: 8px 16px;
    border-radius: 4px;
    cursor: pointer;
    font-size: 14px;
    transition: background-color 0.2s;
}

.copy-position-btn:hover {
    background-color: #45a049;
}

.info {    font-size: 16px;    font-weight: bold;    margin: 5px 0;    color: rgba(232, 232, 255, 0.95);    text-shadow: 0 0 5px rgba(255, 255, 255, 0.3);}.study-status {    font-size: 14px;    color: rgba(232, 232, 255, 0.8);    margin-top: 5px;    text-shadow: 0 0 3px rgba(255, 255, 255, 0.2);}

.board-area {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 20px;
}

.pieces-in-hand-top,
.pieces-in-hand-bottom {
    width: 100%;
    max-width: 450px;
}

.move-history-container {
    flex: 1;
    max-width: 400px;
    min-width: 350px;
}

.move-error-toast {
    position: fixed;
    top: 20px;
    right: 20px;
    background-color: #f44336;
    color: white;
    padding: 12px 20px;
    border-radius: 4px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    z-index: 1000;
    animation: slideIn 0.3s ease-out;
}

@keyframes slideIn {
    from {
        transform: translateX(100%);
        opacity: 0;
    }
    to {
        transform: translateX(0);
        opacity: 1;
    }
}

@media (max-width: 768px) {
    .shogi-container {
        flex-direction: column;
        gap: 20px;
    }
    
    .move-history-container {
        max-width: none;
        min-width: auto;
    }
}
</style> 