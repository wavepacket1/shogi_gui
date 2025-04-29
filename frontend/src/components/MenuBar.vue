<template>
  <header>
    <div 
      class="tab" 
      :class="{ active: currentMode === GameMode.PLAY }"
      @click="changeMode(GameMode.PLAY)"
    >
      対局モード
    </div>
    <div 
      class="tab" 
      :class="{ active: currentMode === GameMode.EDIT }"
      @click="changeMode(GameMode.EDIT)"
    >
      編集モード
    </div>
    <div 
      class="tab" 
      :class="{ active: currentMode === GameMode.STUDY }"
      @click="changeMode(GameMode.STUDY)"
    >
      検討モード
    </div>
    <div v-if="error" class="error-message">{{ error }}</div>
  </header>
</template>

<script lang="ts">
import { defineComponent, ref, computed, onMounted } from 'vue';
import { useModeStore } from '@/store/mode';
import { useBoardStore } from '@/store';
import { GameMode } from '@/store/types';

// メニュー項目の型定義
export interface MenuItemType {
  name: string;
  action: string;
}

export default defineComponent({
  name: 'MenuBar',
  
  setup() {
    // ボードストアとモードストア
    const boardStore = useBoardStore();
    const modeStore = useModeStore();
    
    // 現在のモード
    const currentMode = computed(() => modeStore.currentMode);
    const isLoading = computed(() => modeStore.isLoading);
    const error = computed(() => modeStore.error);
    
    // コンポーネントマウント時にモード初期化
    onMounted(() => {
      modeStore.initializeMode();
    });
    
    // モード変更処理
    const changeMode = async (newMode: GameMode) => {
      if (currentMode.value === newMode || isLoading.value) return;
      
      try {
        if (!boardStore.game?.id) {
          // ゲームが開始されていない場合は、まずゲームを作成
          if (newMode === GameMode.PLAY) {
            await boardStore.createGame();
          }
          return;
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
      GameMode
    };
  }
});
</script>

<style scoped>
header {
  background: #f5f5f5;
  padding: 8px 16px;
  display: flex;
  gap: 16px;
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  box-sizing: border-box;
  z-index: 1000;
}

.tab {
  padding: 6px 12px;
  cursor: pointer;
  border-radius: 4px;
  transition: all 0.2s ease;
}

.tab.active {
  background: #007acc;
  color: #fff;
}

.tab:hover:not(.active) {
  background: #e0e0e0;
}

.error-message {
  color: #ff5252;
  font-size: 0.8rem;
  margin-left: auto;
  align-self: center;
  background: #ffebee;
  padding: 2px 6px;
  border-radius: 4px;
}

@media (max-width: 768px) {
  header {
    flex-wrap: wrap;
  }
}
</style>
  