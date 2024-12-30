<template>
    <div class="game-info">
        <div>手数 {{ getStepNumber }}</div>
        <div>手番 {{ getOwner }}</div>
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

        const getStepNumber = computed(() => boardStore.step_number);

        const getOwner = computed(() => (boardStore.active_player === 'b' ? '先手' : '後手'));

        const initializeGame = async () => {
            try {
                isLoading.value = true;
                await boardStore.createGame();  // ゲームを作成
                console.log('Game initialized:', {
                    game_id: boardStore.game?.id,
                    board_id: boardStore.board_id
                });
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

            return isInPromotionZone;
        };

        const handlePieceClick = (piece: string) => {
            // 先手の場合は大文字の駒のみ、後手の場合は小文字の駒のみ選択可能
            const isUpperCase = piece === piece.toUpperCase();
            if ((boardStore.active_player === 'b' && !isUpperCase) || 
                (boardStore.active_player === 'w' && isUpperCase)) {
                return; // 相手の持ち駒は選択できない
            }
            
            // 既に選択されている駒をクリックした場合は選択解除
            if (selectedHandPiece.value === piece) {
                selectedHandPiece.value = undefined;
                boardStore.SetCell(null);
                return;
            }

            selectedHandPiece.value = piece;
            boardStore.SetCell(null); // 盤面の選択を解除
        };

        const handleCellClick = async (x: number, y: number) => {
            try {
                if (!boardStore.game?.id || !boardStore.board_id) {
                    await initializeGame();
                    return;
                }

                const clickedCell = { x, y };
                const currentPiece = boardStore.shogiData.board[y][x];
                
                if (boardStore.selectedCell.x === null || boardStore.selectedCell.y === null) {
                    if (currentPiece && currentPiece.owner === boardStore.active_player) {
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

        onMounted(async () => {
            await initializeGame();
        });

        return {
            boardStore,
            piecesInHandB: computed(() => {
                const pieces = boardStore.shogiData?.piecesInHand || {};
                const result: { [key: string]: number } = {};
                for (const [piece, count] of Object.entries(pieces)) {
                    if (/[A-Z]/.test(piece)) { // Senteの持ち駒
                        result[piece] = count;
                    }
                }
                return result;
            }),
            piecesInHandW: computed(() => {
                const pieces = boardStore.shogiData?.piecesInHand || {};
                const result: { [key: string]: number } = {};
                for (const [piece, count] of Object.entries(pieces)) {
                    if (/[a-z]/.test(piece)) { // Goteの持ち駒
                        const upperPiece = piece.toUpperCase();
                        result[upperPiece] = count;
                    }
                }
                return result;
            }),
            isLoading,
            errorMessage,
            getStepNumber,
            handleCellClick,
            getOwner,
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
