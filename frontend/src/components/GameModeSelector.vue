<template>
  <div class="game-mode-selector">
    <div class="mode-title">ゲームモード：</div>
    <div class="mode-options">
      <button 
        class="mode-button" 
        :class="{ active: currentMode === GameMode.PLAY }"
        @click="changeMode(GameMode.PLAY)"
        :disabled="isLoading || !canChangeMode"
        data-test="play-mode-button"
      >
        対局モード
      </button>
      <button 
        class="mode-button" 
        :class="{ active: currentMode === GameMode.EDIT }"
        @click="changeMode(GameMode.EDIT)"
        :disabled="isLoading || !canChangeMode"
        data-test="edit-mode-button"
      >
        編集モード
      </button>
      <button 
        class="mode-button" 
        :class="{ active: currentMode === GameMode.STUDY }"
        @click="changeMode(GameMode.STUDY)"
        :disabled="isLoading || !canChangeMode"
        data-test="study-mode-button"
      >
        検討モード
      </button>
    </div>
    <div v-if="error" class="error-message">{{ error }}</div>
    <div v-if="isLoading" class="loading">処理中...</div>
  </div>
</template>

<script lang="ts">
import { defineComponent, computed, onMounted, ref } from 'vue';
import { useModeStore } from '@/store/mode';
import { useBoardStore } from '@/store';
import { GameMode } from '@/store/types';

export default defineComponent({
  name: 'GameModeSelector',
  
  setup() {
    const modeStore = useModeStore();
    const boardStore = useBoardStore();
    
    // ゲームが存在するかどうか
    const canChangeMode = computed(() => !!boardStore.game?.id);
    
    // 現在のモード（store から reactive に取得）
    const currentMode = computed(() => modeStore.currentMode);
    const isLoading = computed(() => modeStore.isLoading);
    const error = computed(() => modeStore.error);
    
    // コンポーネントマウント時にモード初期化
    onMounted(() => {
      modeStore.initializeMode();
    });
    
    // モード変更処理
    const changeMode = async (newMode: GameMode) => {
      if (currentMode.value === newMode || !canChangeMode.value) return;
      
      try {
        if (!boardStore.game?.id) {
          throw new Error('ゲームが開始されていません');
        }
        
        await modeStore.changeMode(boardStore.game.id, newMode);
      } catch (err) {
        console.error('モード変更中にエラーが発生しました:', err);
      }
    };
    
    return {
      currentMode,
      isLoading,
      error,
      changeMode,
      canChangeMode,
      GameMode
    };
  }
});
</script>

<style scoped>
.game-mode-selector {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 10px 0;
  padding: 10px;
  border-radius: 8px;
  background: rgba(30, 30, 60, 0.9);
  backdrop-filter: blur(15px);
  box-shadow: 
    0 4px 8px rgba(0,0,0,0.2),
    0 0 20px rgba(138, 43, 226, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.mode-title {
  font-weight: bold;
  margin-bottom: 8px;
  font-size: 1rem;
  color: rgba(232, 232, 255, 0.95);
  text-shadow: 0 0 5px rgba(255, 255, 255, 0.3);
}

.mode-options {
  display: flex;
  gap: 10px;
}

.mode-button {
  padding: 8px 16px;
  border: 1px solid #ccc;
  border-radius: 4px;
  background: rgba(30, 30, 60, 0.95);
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.9rem;
}

.mode-button:hover:not(:disabled) {
  background: rgba(74, 144, 226, 0.3);
  border-color: rgba(74, 144, 226, 0.6);
  box-shadow: 0 6px 12px rgba(74, 144, 226, 0.2);
  transform: translateY(-1px);
}

.mode-button.active {
  background-color: #4CAF50;
  color: white;
  border-color: #4CAF50;
  font-weight: bold;
}

.mode-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.error-message {
  color: #ff6b6b;
  margin-top: 8px;
  font-size: 0.85rem;
  background: rgba(40, 20, 20, 0.8);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 107, 107, 0.3);
  padding: 4px 8px;
  border-radius: 4px;
  max-width: 90%;
  text-shadow: 0 0 3px rgba(255, 107, 107, 0.3);
}

.loading {
  margin-top: 8px;
  font-size: 0.85rem;
  color: rgba(232, 232, 255, 0.7);
  text-shadow: 0 0 3px rgba(255, 255, 255, 0.2);
}

@media (max-width: 600px) {
  .mode-options {
    flex-direction: column;
    gap: 5px;
  }
  
  .mode-button {
    width: 100%;
  }
}
</style> 