<template>
    <div class="game-info">
        <div>手数 {{ getStepNumber }}</div>
        <div>手番 {{ getOwner }}</div>
    </div>

    <div class="shogi-container">
        <PiecesInHand 
            class="pieces-in-hand-top" 
            :pieces="piecesInHandW" 
        />

        <ShogiBoardGrid 
            :board="boardStore.shogiData.board"
            :selectedCell="boardStore.selectedCell"
            @cell-click="handleCellClick"
        />

        <PiecesInHand 
            class="pieces-in-hand-bottom" 
            :pieces="piecesInHandB" 
        />
    </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, computed } from 'vue';
import { useBoardStore } from '@/store';
import PiecesInHand from './PiecesInHand.vue';
import ShogiBoardGrid from './ShogiBoardGrid.vue';

export default defineComponent({
    name: 'ShogiBoard',
    components: {
        PiecesInHand,
        ShogiBoardGrid,
    },
    setup() {
        const boardStore = useBoardStore();
        const isLoading = ref(true);
        const errorMessage = ref('');

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

        const handleCellClick = async (x: number, y: number) => {
            try {
                if (!boardStore.game?.id || !boardStore.board_id) {
                    console.error('Game not initialized:', {
                        game: boardStore.game,
                        board_id: boardStore.board_id
                    });
                    await initializeGame();
                    return;
                }

                const clickedCell = { x, y };
                const currentPiece = boardStore.shogiData.board[y][x];
                
                if (boardStore.selectedCell.x === null || boardStore.selectedCell.y === null) {
                    if (currentPiece && currentPiece.owner === boardStore.active_player) {
                        boardStore.SetCell(clickedCell);
                        console.log('Selected piece:', currentPiece);
                    }
                    return;
                }

                if (boardStore.selectedCell.x === x && boardStore.selectedCell.y === y) {
                    boardStore.SetCell(null);
                    return;
                }

                await boardStore.movePiece(boardStore.game.id, boardStore.board_id, x, y);

            } catch (error) {
                console.error('Error in handleCellClick:', error);
                boardStore.SetCell(null);
            }
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
