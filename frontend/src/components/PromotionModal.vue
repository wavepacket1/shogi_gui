<template>
    <div v-if="isOpen" class="modal-overlay">
        <div class="modal-content">
            <h3>駒を成りますか？</h3>
            <div class="button-group">
                <button class="promote-button" @click="$emit('promote', true)">成る</button>
                <button class="cancel-button" @click="$emit('promote', false)">成らない</button>
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';

export default defineComponent({
    name: 'PromotionModal',
    props: {
        isOpen: {
            type: Boolean,
            required: true
        }
    },
    emits: ['promote']
});
</script>

<style scoped>
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background: rgba(0, 0, 0, 0.5);
    display: flex;
    justify-content: center;
    align-items: center;
    z-index: 1000;
}

.modal-content {
    background: #fff;
    padding: 20px;
    border-radius: 8px;
    box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
    text-align: center;
}

h3 {
    margin: 0 0 20px 0;
    color: #333;
    font-size: 18px;
}

.button-group {
    display: flex;
    gap: 10px;
    justify-content: center;
}

button {
    padding: 10px 20px;
    border: none;
    border-radius: 4px;
    cursor: pointer;
    font-weight: bold;
    transition: background-color 0.2s;
}

.promote-button {
    background-color: #4CAF50;
    color: white;
}

.promote-button:hover {
    background-color: #45a049;
}

.cancel-button {
    background-color: #f44336;
    color: white;
}

.cancel-button:hover {
    background-color: #da190b;
}
</style> 