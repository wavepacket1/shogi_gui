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
    background: rgba(244, 240, 236, 0.9);
    border-radius: 8px;
}

.piece-container {
    perspective: 600px;
}

.piece-shape {
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
}

.piece-count {
    position: absolute;
    bottom: 2px;
    right: 2px;
    font-size: 10px;
    color: #000000;
    background: rgba(255, 255, 255, 0.8);
    padding: 0px 2px;
    border-radius: 2px;
    transform-origin: center;
    text-shadow: 0 1px 1px rgba(255, 255, 255, 0.8);
}

.piece-shape.gote {
    transform: rotate(180deg);
}

.piece-shape.gote .piece-symbol {
    transform: scaleY(1.3);
}

.piece-shape.gote .piece-count {
    transform: rotate(180deg);
}

.piece-shape.selected {
    background: 
        repeating-linear-gradient(
            -65deg,
            #E4C38B 0px,
            #E4C38B 4px,
            #D4B375 4px,
            #D4B375 8px
        ),
        linear-gradient(
            155deg,
            #F4D39B 0%,
            #D4B375 45%,
            #C4A365 80%,
            #B39355 100%
        );
    box-shadow: 
        0 0 0 2px #FFD700,
        0 2px 4px rgba(0, 0, 0, 0.2),
        inset 0 1px 3px rgba(255, 255, 255, 0.6);
}

.piece-shape:hover {
    cursor: pointer;
    filter: brightness(1.1);
}
</style>
