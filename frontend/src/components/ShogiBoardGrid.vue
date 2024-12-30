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
                <div v-if="board[y][x]" class="piece-shape" :class="[board[y][x].owner]">
                    <div class="piece-symbol">{{ getJapanesePiece(board[y][x]) }}</div>
                </div>
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
    border: 3px solid #4A3728;
    width: 450px;
    height: 450px;
    margin: 20px auto;
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
        0 2px 4px rgba(0, 0, 0, 0.1),
        inset 0 1px 3px rgba(255, 255, 255, 0.6);
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

.shogi-cell.selected {
    background-color: rgba(255, 216, 102, 0.5);
    box-shadow: inset 0 0 5px rgba(139, 115, 85, 0.5);
}
</style>
