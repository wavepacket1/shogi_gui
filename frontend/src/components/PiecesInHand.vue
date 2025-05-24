<template>
    <div class="pieces-in-hand">
        <div v-for="(count, piece) in pieces" :key="piece" class="piece-container" @click="() => $emit('piece-click', piece)">
            <div class="piece-shape" :class="{ 'gote': isGote, 'selected': selectedPiece === piece }">
                <div class="piece-symbol">{{ pieceMapper[piece] }}</div>
                <div class="piece-count" v-if="count > 1">{{ count }}</div>
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import type { PropType } from 'vue';
import { pieceMapper } from '@/utils/pieceMapper';

export default defineComponent({
    name: 'PiecesInHand',
    props: {
        pieces: {
            type: Object as PropType<Record<string, number>>,
            required: true,
        },
        isGote: {
            type: Boolean,
            default: false
        },
        selectedPiece: {
            type: String,
            default: undefined
        }
    },
    emits: ['piece-click'],
    setup(props, { emit }) {
        const handlePieceClick = (piece: string) => {
            emit('piece-click', piece);
        };

        return {
            pieceMapper,
            handlePieceClick
        };
    },
});
</script>

<style scoped>
.pieces-in-hand {
    display: flex;
    justify-content: center;
    gap: 12px;
    width: 450px;
    padding: 15px;
    background: rgba(30, 30, 60, 0.8);
    backdrop-filter: blur(10px);
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 8px;
}

.piece-container {
    perspective: 600px;
}

.piece-shape {
    cursor: pointer;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    width: 30px;
    height: 45px;
    position: relative;
    transform-style: preserve-3d;
    transition: none;
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
    border: 1px solid rgba(255, 255, 255, 0.3);
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
}

.piece-count {
    position: absolute;
    bottom: 2px;
    right: 2px;
    font-size: 10px;
    color: #2d1e0f;
    background: rgba(255, 255, 255, 0.9);
    padding: 0px 2px;
    border-radius: 2px;
    transform-origin: center;
    text-shadow: 0 1px 1px rgba(255, 255, 255, 0.8);
}

.piece-shape.gote {    transform: rotate(180deg);    /* 先手駒と同じ色に統一、回転のみで区別 */}

.piece-shape.gote .piece-symbol {
    transform: scaleY(1.3);
}

.piece-shape.gote .piece-count {
    transform: rotate(180deg);
}

.piece-shape.selected {
    background: 
        linear-gradient(
            155deg,
            rgba(255, 216, 102, 0.95) 0%,
            rgba(255, 230, 150, 0.9) 30%,
            rgba(255, 210, 120, 0.85) 70%,
            rgba(220, 190, 100, 0.9) 100%
        );
    box-shadow: 
        0 0 0 2px rgba(255, 216, 102, 0.8),
        0 4px 8px rgba(0, 0, 0, 0.3),
        0 0 20px rgba(255, 216, 102, 0.4),
        inset 0 1px 3px rgba(255, 255, 255, 0.8);
    border-color: rgba(255, 216, 102, 0.8);
}

.piece-shape:hover {
    cursor: pointer;
    box-shadow: 
        0 6px 12px rgba(0, 0, 0, 0.4),
        0 0 20px rgba(255, 255, 255, 0.3),
        inset 0 1px 3px rgba(255, 255, 255, 0.9);
    border-color: rgba(255, 255, 255, 0.5);
}
</style>
