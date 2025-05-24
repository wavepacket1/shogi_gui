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
import * as types from '@/store/types';

export default defineComponent({
    name: 'ShogiBoardGrid',
    props: {
        board: {
            type: Array as PropType<(types.ShogiPiece | null)[][]>,
            required: true,
        },
        selectedCell: {
            type: Object as PropType<{x: number | null, y: number | null}>,
            required: true
        }
    },
    setup(props) {
        const getJapanesePiece = (piece: types.ShogiPiece): string => {
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
    border: 3px solid rgba(138, 43, 226, 0.6);
    width: 450px;
    height: 450px;
    margin: 20px auto;
    background: 
        radial-gradient(circle at 20% 20%, rgba(138, 43, 226, 0.3) 0%, transparent 50%),
        radial-gradient(circle at 80% 80%, rgba(74, 144, 226, 0.2) 0%, transparent 50%),
        radial-gradient(circle at 40% 70%, rgba(30, 30, 60, 0.4) 0%, transparent 50%),
        linear-gradient(135deg, rgba(25, 25, 50, 0.9) 0%, rgba(40, 40, 80, 0.8) 100%);
    box-shadow: 
        0 8px 20px rgba(0, 0, 0, 0.4),
        0 0 30px rgba(138, 43, 226, 0.3),
        inset 0 1px 0 rgba(255, 255, 255, 0.1);
    backdrop-filter: blur(10px);
    border-radius: 8px;
    position: relative;
    overflow: hidden;
}

.shogi-board::before {
    content: '';
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: 
        radial-gradient(2px 2px at 20px 30px, rgba(255, 255, 255, 0.4), transparent),
        radial-gradient(2px 2px at 40px 70px, rgba(255, 255, 255, 0.3), transparent),
        radial-gradient(1px 1px at 90px 40px, rgba(255, 255, 255, 0.6), transparent),
        radial-gradient(1px 1px at 130px 80px, rgba(255, 255, 255, 0.4), transparent),
        radial-gradient(2px 2px at 160px 30px, rgba(255, 255, 255, 0.3), transparent);
    background-repeat: repeat;
    background-size: 200px 100px;
    animation: twinkle 4s ease-in-out infinite alternate;
    pointer-events: none;
}

@keyframes twinkle {
    0% { opacity: 0.3; }
    100% { opacity: 0.8; }
}

.shogi-row {
    display: contents;
}

.shogi-cell {
    border: 1px solid rgba(255, 255, 255, 0.15);
    display: flex;
    align-items: center;
    justify-content: center;
    position: relative;
    background: rgba(30, 30, 60, 0.3);
    cursor: pointer;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    backdrop-filter: blur(5px);
}

.shogi-cell:hover {
    background: rgba(74, 144, 226, 0.2);
    border-color: rgba(74, 144, 226, 0.5);
    box-shadow: 
        inset 0 0 10px rgba(74, 144, 226, 0.3),
        0 0 15px rgba(74, 144, 226, 0.2);
    transform: translateZ(0);
}

.piece-shape {
    cursor: pointer;
    width: 30px;
    height: 45px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    position: relative;
    transition: all 0.3s ease;
    clip-path: polygon(
        50% 0%,
        100% 35%,
        100% 100%,
        0% 100%,
        0% 35%
    );
    background: 
        linear-gradient(
            155deg,
            rgba(255, 255, 255, 0.95) 0%,
            rgba(230, 230, 255, 0.9) 30%,
            rgba(200, 200, 240, 0.85) 70%,
            rgba(180, 180, 220, 0.9) 100%
        );
    box-shadow: 
        0 4px 8px rgba(0, 0, 0, 0.3),
        0 0 15px rgba(255, 255, 255, 0.2),
        inset 0 1px 3px rgba(255, 255, 255, 0.8);
    transform: rotate(0deg);
    border: 1px solid rgba(255, 255, 255, 0.3);
}

.piece-shape:hover {
    transform: translateY(-2px) scale(1.05);
    box-shadow: 
        0 6px 12px rgba(0, 0, 0, 0.4),
        0 0 20px rgba(255, 255, 255, 0.3),
        inset 0 1px 3px rgba(255, 255, 255, 0.9);
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
            rgba(255, 255, 255, 0.6) 0%,
            rgba(255, 245, 225, 0.3) 30%,
            rgba(255, 235, 205, 0.2) 70%,
            rgba(0, 0, 0, 0.05) 100%
        );
    clip-path: inherit;
    pointer-events: none;
}

.piece-symbol {
    font-size: 16px;
    font-weight: bold;
    color: #2d1e0f;
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
    z-index: 1;
    position: relative;
}

.piece-shape.w {
    transform: rotate(180deg);
    background: 
        linear-gradient(
            155deg,
            rgba(255, 200, 200, 0.95) 0%,
            rgba(255, 220, 220, 0.9) 30%,
            rgba(240, 200, 200, 0.85) 70%,
            rgba(220, 180, 180, 0.9) 100%
        );
}

.piece-shape.w:hover {
    transform: rotate(180deg) translateY(-2px) scale(1.05);
}

.piece-shape.w .piece-symbol {
    transform: scaleY(1.3);
    color: #2d1e0f;
}

.shogi-cell.selected {
    background: rgba(255, 216, 102, 0.4);
    border-color: rgba(255, 216, 102, 0.8);
    box-shadow: 
        inset 0 0 15px rgba(255, 216, 102, 0.5),
        0 0 20px rgba(255, 216, 102, 0.4);
    animation: selectedPulse 2s ease-in-out infinite alternate;
}

@keyframes selectedPulse {
    0% { 
        box-shadow: 
            inset 0 0 15px rgba(255, 216, 102, 0.5),
            0 0 20px rgba(255, 216, 102, 0.4);
    }
    100% { 
        box-shadow: 
            inset 0 0 25px rgba(255, 216, 102, 0.7),
            0 0 30px rgba(255, 216, 102, 0.6);
    }
}

/* タブレット対応（768px以下） */
@media (max-width: 768px) {
    .shogi-board {
        width: 360px;
        height: 360px;
        grid-template-rows: repeat(9, 40px);
        grid-template-columns: repeat(9, 40px);
        margin: 15px auto;
        border-width: 2px;
        border-radius: 6px;
    }
    
    .piece-shape {
        width: 24px;
        height: 36px;
    }
    
    .piece-symbol {
        font-size: 13px;
        margin-top: 10px;
    }
}

/* スマートフォン対応（480px以下） */
@media (max-width: 480px) {
    .shogi-board {
        width: 300px;
        height: 300px;
        grid-template-rows: repeat(9, 33px);
        grid-template-columns: repeat(9, 33px);
        margin: 10px auto;
        border-width: 2px;
        border-radius: 4px;
    }
    
    .shogi-board::before {
        background-size: 150px 75px;
    }
    
    .shogi-cell {
        border-width: 0.5px;
    }
    
    .piece-shape {
        width: 20px;
        height: 30px;
    }
    
    .piece-symbol {
        font-size: 11px;
        margin-top: 8px;
    }
}

/* 極小画面対応（360px以下） */
@media (max-width: 360px) {
    .shogi-board {
        width: 270px;
        height: 270px;
        grid-template-rows: repeat(9, 30px);
        grid-template-columns: repeat(9, 30px);
        margin: 5px auto;
        border-width: 1px;
        border-radius: 4px;
    }
    
    .shogi-board::before {
        background-size: 120px 60px;
    }
    
    .shogi-cell {
        border-width: 0.5px;
    }
    
    .piece-shape {
        width: 18px;
        height: 26px;
    }
    
    .piece-symbol {
        font-size: 10px;
        margin-top: 6px;
        transform: scaleY(1.2);
    }
}

/* タッチデバイス最適化 */
@media (hover: none) and (pointer: coarse) {
    .shogi-cell:active {
        background: rgba(74, 144, 226, 0.4);
        transform: scale(0.95);
        transition: all 0.1s ease;
    }
    
    .piece-shape:hover {
        transform: none;
    }
    
    .piece-shape:active {
        transform: scale(0.9);
    }
}

/* アクセシビリティ対応 */
@media (prefers-reduced-motion: reduce) {
    .shogi-cell,
    .piece-shape,
    .piece-symbol {
        transition: none !important;
    }
    
    .shogi-board::before {
        animation: none !important;
    }
    
    .shogi-cell.selected {
        animation: none !important;
    }
}

/* 高コントラストモード */
@media (prefers-contrast: high) {
    .shogi-board {
        border-color: #fff;
        background: #000;
    }
    
    .shogi-cell {
        border-color: #fff;
        background: #333;
    }
    
    .shogi-cell.selected {
        background: #ff0 !important;
        color: #000 !important;
    }
    
    .piece-shape {
        background: #fff !important;
        border-color: #000;
    }
    
    .piece-symbol {
        color: #000 !important;
        text-shadow: none !important;
        font-weight: 900;
    }
}
</style>



