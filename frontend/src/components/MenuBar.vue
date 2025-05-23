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
  background: rgba(20, 20, 40, 0.95); /* 半透明の宇宙色 */
  padding: 12px 20px;
  display: flex;
  gap: 20px;
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  box-sizing: border-box;
  z-index: 1000;
  backdrop-filter: blur(15px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 
    0 4px 8px rgba(0,0,0,0.3),
    0 0 20px rgba(138, 43, 226, 0.2),
    inset 0 1px 0 rgba(255, 255, 255, 0.1);
}

.tab {
  padding: 10px 18px;
  cursor: pointer;
  border-radius: 8px;
  transition: all 0.3s ease;
  font-weight: 500;
  color: #E8E8FF;
  text-shadow: 0 0 5px rgba(255, 255, 255, 0.3);
  background: rgba(40, 40, 80, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
}

.tab.active {
  background: linear-gradient(145deg, #4A90E2, #357ABD);
  color: white;
  box-shadow: 
    0 4px 8px rgba(0,0,0,0.3),
    0 0 15px rgba(74, 144, 226, 0.5),
    inset 0 1px 0 rgba(255, 255, 255, 0.2);
  text-shadow: 0 1px 2px rgba(0,0,0,0.3);
  transform: translateY(-1px);
}

.tab:hover:not(.active) {
  background: rgba(60, 60, 120, 0.5);
  color: #F0F0FF;
  box-shadow: 
    0 4px 8px rgba(0,0,0,0.2),
    0 0 10px rgba(255, 255, 255, 0.2);
  transform: translateY(-1px);
}

.error-message {
  color: #FFB8B8;
  font-size: 0.9rem;
  margin-left: auto;
  align-self: center;
  background: rgba(60, 20, 20, 0.8);
  padding: 6px 12px;
  border-radius: 6px;
  border: 1px solid rgba(255, 100, 100, 0.3);
  text-shadow: 0 0 5px rgba(255, 100, 100, 0.5);
  backdrop-filter: blur(10px);
  box-shadow: 
    0 2px 4px rgba(0,0,0,0.2),
    0 0 10px rgba(255, 100, 100, 0.2);
}

@media (max-width: 768px) {
  header {
    flex-wrap: wrap;
    padding: 10px 15px;
    gap: 15px;
  }
  
  .tab {
    padding: 8px 15px;
    font-size: 0.9rem;
  }
}
</style>
  