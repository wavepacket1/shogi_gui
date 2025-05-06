<template>
  <button
    class="resign-button"
    :disabled="disabled || isLoading"
    @click="handleResign"
  >
    <span v-if="isLoading">投了中...</span>
    <span v-else>投了</span>
  </button>
</template>

<script lang="ts">
import { defineComponent, ref } from 'vue';
import { useBoardStore } from '@/store';

export default defineComponent({
  name: 'ResignButton',
  props: {
    gameId: {
      type: Number,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['resign-complete'],
  setup(props, { emit }) {
    const isLoading = ref(false);
    const boardStore = useBoardStore();

    const handleResign = async () => {
      if (!confirm('本当に投了しますか？')) {
        return;
      }

      try {
        isLoading.value = true;
        await boardStore.resignGame(props.gameId);
        emit('resign-complete');
      } catch (error) {
        console.error('投了処理に失敗しました:', error);
        // エラーメッセージを表示するなどの処理を追加可能
      } finally {
        isLoading.value = false;
      }
    };

    return {
      isLoading,
      handleResign,
    };
  },
});
</script>

<style scoped>
.resign-button {
  padding: 8px 16px;
  font-size: 14px;
  color: white;
  background-color: #dc3545;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: background-color 0.2s, opacity 0.2s;
}

.resign-button:hover:not(:disabled) {
  background-color: #c82333;
}

.resign-button:active:not(:disabled) {
  transform: translateY(1px);
}

.resign-button:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}
</style>