<template>
  <div id="app">
    <MenuBar />
    <div class="main-content">
      <component :is="currentComponent" />
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, computed } from 'vue';
import ShogiBoard from './components/ShogiBoard.vue';
import EditBoard from './components/EditBoard.vue';
import MenuBar from './components/MenuBar.vue';
import { useModeStore } from './store/mode';
import { GameMode } from './store/types';

export default defineComponent({
  name: 'App',
  components: {
    ShogiBoard,
    EditBoard,
    MenuBar
  },
  setup() {
    const modeStore = useModeStore();

    // 現在のモードに基づいて表示するコンポーネントを決定
    const currentComponent = computed(() => {
      switch (modeStore.currentMode) {
        case GameMode.EDIT:
          return 'EditBoard';
        case GameMode.PLAY:
        case GameMode.STUDY:
        default:
          return 'ShogiBoard';
      }
    });

    return {
      currentComponent
    };
  }
});
</script>

<style>
#app {
  text-align: center;
  user-select: none;        
  -webkit-user-select: none;
}

.main-content {
  margin-top: 60px; /* MenuBarの高さ + 余白 */
  padding: 20px;
}

.game-controls {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 1rem;
  margin-bottom: 1rem;
}
</style>