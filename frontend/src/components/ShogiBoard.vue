<template>
    <div> 手数 {{  getStepNumber }}</div>
    <div> 手番 {{ getOwner }}</div>

    <div class = "shogi-container">
        <div class="pieces-in-hand pieces-in-hand-top">
            <div v-for="(count, piece) in piecesInHandW" :key="piece" class="piece">
                {{ pieceMapper[piece] }} x{{ count }}
            </div>
        </div>

        <div class="shogi-board">
            <div
            v-for="y in Array.from({ length: 9 }, (_, i) => i)"
            :key="'row-' + y"
            class="shogi-row"
            >
                <div
                v-for="x in Array.from({ length: 9 }, (_, i) => i)"
                :key="'cell-' + x + '-' + y"
                class="shogi-cell"
                :data-x="x"
                :data-y="y"
                @click="handleCellClick(x, y)"
                >
                    <span
                        v-if="getPiece(x, y)"
                        :class="['shogi-piece', getPiece(x, y).owner]"
                        :data-id="getPiece(x, y).id"
                    >
                        {{ getJapanesePiece(getPiece(x, y)) }}
                    </span>
                </div>
            </div>
        </div>

        <div class="pieces-in-hand pieces-in-hand-bottom">
            <div v-for="(count, piece) in piecesInHandB" :key="piece" class="piece">
                {{ pieceMapper[piece] }} x{{ count }}
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { defineComponent, ref, onMounted, computed } from 'vue';
import { useBoardStore } from '@/store';
import { pieceMapper } from '@/utils/pieceMapper';

interface ShogiPiece {
    piece_type: string;
    promoted: boolean;
    owner: 'b' | 'w';
    id: number;
    position_x: number;
    position_y: number;
}

interface Cell {
	x: number;
	y: number;
} 


export default defineComponent({
    name: 'ShogiBoard',
    setup() {
        const boardStore = useBoardStore();
        const isLoading = ref(true);
        const isError = ref(false);
        const errorMessage = ref('');

        const getJapanesePiece = (piece: ShogiPiece): string => {
            if (!piece) return '';
            const key = piece.promoted ? `+${piece.piece_type}` : piece.piece_type;
            return pieceMapper[key] || '';
        };

        const piecesInHandB = computed(() => {
            const pieces = boardStore.shogiData?.piecesInHand || {};
            const result: { [key: string]: number } = {};
            for (const [piece, count] of Object.entries(pieces)) {
                if (/[A-Z]/.test(piece)) { // Senteの持ち駒
                    result[piece] = count;
                }
            }
            return result;
        });

        const piecesInHandW = computed(() => {
            const pieces = boardStore.shogiData?.piecesInHand || {};
            const result: { [key: string]: number } = {};
            for (const [piece, count] of Object.entries(pieces)) {
                if (/[a-z]/.test(piece)) { // Goteの持ち駒
                    const upperPiece = piece.toUpperCase();
                    result[upperPiece] = count;
                }
            }
            return result;
        });

        const getPiece = (x: number, y: number): ShogiPiece | null => {
            const piece = boardStore.shogiData.board[y][x]
            return piece;
        }

        const selectedPiece = ref<ShogiPiece | null>(null);

        const handleCellClick = (x: number, y: number) => {
            
	const clickedCell = { x, y }
//
//	if(boardStore.selectedCell){
//		boardStore.setMoveToCell(clickedCell)
//		boardStore.movePiece(selectedPiece.value.id, x, y);
//		boardStore.setMoveToCell(null);	
//	} else {
//		boardStore.setSelectedCell(clickedCell)
//	};
}
	    
//const piece = getPiece(x, y);
//            if (selectedPiece.value) {
//                // 移動を試みる
//                boardStore.movePiece(selectedPiece.value.id, x, y);
//                selectedPiece.value = null;
//            } else if (piece) {
//                selectedPiece.value = piece;
//            }
//        };

        const fetchDefaultBoard = async () => {
            try {
                isLoading.value = true;
                await boardStore.getDefaultBoard();
            } catch (error) {
                console.error('エラー:', error);
                errorMessage.value = 'デフォルト盤面の取得に失敗しました。';
            } finally {
                isLoading.value = false;
            }
        };

        const getStepNumber = computed(() => {
            if (boardStore.game !== null) {
                return boardStore.step_number;
            }
        });

        const getOwner = computed(() => {
            if (boardStore.game !== null) {
                return boardStore.active_player==='b' ? '先手' : '後手';
            }
        });

        onMounted(() => {
            fetchDefaultBoard();
        });

        return {
            getJapanesePiece,
            piecesInHandB,
            piecesInHandW,
            pieceMapper,
            isLoading,
            isError,
            errorMessage,
            getPiece,
            getStepNumber,
            handleCellClick,
            getOwner
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

.pieces-in-hand {
    display: flex;
    justify-content: center;
    gap: 5px;
    width: 450px;
}

.pieces-in-hand-top {
    order: 1;
}

.pieces-in-hand-bottom {
    order: 3;
}

/* 既存のスタイルを維持 */
.shogi-board {
    order: 2;
    display: grid;
    grid-template-rows: repeat(9, 50px);
    grid-template-columns: repeat(9, 50px);
    border: 2px solid #333;
    width: 450px;
    height: 450px;
    margin: 20px auto;
    background-color: #f0d9b5;
}

.shogi-row {
    display: contents;
}

.shogi-cell {
    border: 1px solid #999;
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    background-color: #f0d9b5;
}

.shogi-piece {
    font-size: 24px;
    font-weight: bold;
    cursor: grab;
}

.shogi-piece.b {
    color: black;
}

.shogi-piece.w {
    color: black;
    transform: rotate(180deg);
}
</style>
