<template>
    <div class="shogi-board">
        <div v-for="y in Array.from({ length: 9 }, (_, i) => i)" :key="'row-' + y" class="shogi-row">
            <div
                v-for="x in Array.from({ length: 9 }, (_, i) => i)"
                :key="'cell-' + x + '-' + y"
                class="shogi-cell"
                :class="{ 'selected': isSelected(x, y) }"
                :data-x="x"
                :data-y="y"
                @click="() => $emit('cellClick', x, y)"
            >
                <span v-if="board[y][x]" :class="['shogi-piece', board[y][x].owner]" :data-id="board[y][x].id">
                    {{ getJapanesePiece(board[y][x]) }}
                </span>
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import type { PropType } from 'vue';
import { pieceMapper } from '@/utils/pieceMapper';
import type { ShogiPiece } from '@/store';

export default defineComponent({
    name: 'ShogiBoardGrid',
    props: {
        board: {
            type: Array as PropType<(ShogiPiece | null)[][]>,
            required: true,
        },
        selectedCell: {
            type: Object as PropType<{x: number | null, y: number | null}>,
            required: true
        }
    },
    setup(props) {
        const getJapanesePiece = (piece: ShogiPiece): string => {
            if (!piece) return '';
            const key = piece.promoted ? `+${piece.piece_type}` : piece.piece_type;
            return pieceMapper[key] || '';
        };

        const isSelected = (x: number, y: number) => {
            return props.selectedCell.x === x && props.selectedCell.y === y;
        };

        return {
            getJapanesePiece,
            isSelected
        };
    },
});
</script>

<style scoped>
.shogi-board {
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

.shogi-cell.selected {
    background-color: rgba(255, 255, 0, 0.3);
    box-shadow: inset 0 0 5px rgba(0, 0, 0, 0.3);
}
</style>
