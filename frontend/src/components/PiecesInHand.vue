<template>
    <div class="pieces-in-hand">
        <div v-for="(count, piece) in pieces" :key="piece" class="piece">
            {{ pieceMapper[piece] }} x{{ count }}
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
    },
    setup(props) {
        return {
            pieceMapper,
        };
    },
});
</script>

<style scoped>
.pieces-in-hand {
    display: flex;
    justify-content: center;
    gap: 5px;
    width: 450px;
}
</style>
