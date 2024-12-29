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

        const handleCellClick = (x: number, y: number) => {
            const clickedCell = { x, y };
            
            if (boardStore.selectedCell) {
                if (boardStore.game_id === null || boardStore.board_id === null) return;
                boardStore.SetCell(clickedCell);
                boardStore.movePiece(boardStore.game_id, boardStore.board_id, x, y);
                boardStore.SetCell(null);
            } else {
                boardStore.SetCell(clickedCell);
            }
        };

        const fetchDefaultBoard = async () => {
            try {
                isLoading.value = true;
                await boardStore.fetchBoard();
            } catch (error) {
                errorMessage.value = '将棋盤の読み込みに失敗しました';
                console.error('Error fetching board:', error);
            } finally {
                isLoading.value = false;
            }
        };

        onMounted(() => {
            fetchDefaultBoard();
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
    order: 1;
}

.pieces-in-hand-bottom {
    order: 3;
}

.game-info {
    text-align: center;
    margin-bottom: 10px;
}
</style>
