<template>
    <div class="game-info">
        <div>手数 {{ getStepNumber }}</div>
        <div>手番 {{ getOwner }}</div>
        <div>{{ getGameState }}</div>
    </div>

    <div class="shogi-container">
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

    <PromotionModal 
        :is-open="showPromotionModal"
        @promote="handlePromotion"
    />
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, computed } from 'vue';
import { useBoardStore } from '@/store';
import PiecesInHand from './PiecesInHand.vue';
import ShogiBoardGrid from './ShogiBoardGrid.vue';
import PromotionModal from './PromotionModal.vue';

export default defineComponent({
    name: 'ShogiBoard',
    components: {
        PiecesInHand,
        ShogiBoardGrid,
        PromotionModal
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
            if (boardStore.is_checkmate) {
                return boardStore.activePlayer === 'b' ? '後手勝ち' : '先手勝ち';
            }
            if (boardStore.is_repetition) {
                return '千日手';
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
        };
    },
});
</script>

<style scoped>
.shogi-container {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 10px;
}

.pieces-in-hand-top {
    order: 0;
}

.pieces-in-hand-bottom {
    order: 2;
}

.game-info {
    text-align: center;
    margin-bottom: 10px;
}
</style>
