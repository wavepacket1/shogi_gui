<template>
  <div id="app">
    <MenuBar />
    <div class="main-content">
      <component :is="currentComponent" />
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, computed, onMounted } from 'vue';
import ShogiBoard from './components/ShogiBoard.vue';
import StudyBoard from './components/StudyBoard.vue';
import EditBoard from './components/EditBoard.vue';
import MenuBar from './components/MenuBar.vue';
import { useModeStore } from './store/mode';
import { GameMode } from './store/types';

export default defineComponent({
  name: 'App',
  components: {
    ShogiBoard,
    StudyBoard,
    EditBoard,
    MenuBar
  },
  setup() {
    const modeStore = useModeStore();

    // 初期化時にURLからモードを取得
    onMounted(() => {
      console.log('🚀 アプリケーション初期化: URLからモードを設定');
      modeStore.initializeModeFromUrl();
      console.log('現在のモード:', modeStore.currentMode);
    });

    // 現在のモードに基づいて表示するコンポーネントを決定
    const currentComponent = computed(() => {
      switch (modeStore.currentMode) {
        case GameMode.EDIT:
          return 'EditBoard';
        case GameMode.STUDY:
          return 'StudyBoard';
        case GameMode.PLAY:
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
  min-height: 100vh;
  
  /* 宇宙っぽい背景を全体に適用 */
  background: 
    /* 銀河の渦巻き効果 */
    radial-gradient(ellipse at 20% 50%, rgba(120, 119, 198, 0.3) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, rgba(255, 119, 198, 0.3) 0%, transparent 50%),
    radial-gradient(ellipse at 40% 80%, rgba(120, 219, 255, 0.3) 0%, transparent 50%),
    /* 星の背景 */
    radial-gradient(circle at 25% 25%, #fff 1px, transparent 1px),
    radial-gradient(circle at 75% 75%, #fff 0.5px, transparent 0.5px),
    radial-gradient(circle at 90% 40%, #fff 1px, transparent 1px),
    radial-gradient(circle at 10% 80%, #fff 0.5px, transparent 0.5px),
    radial-gradient(circle at 50% 10%, #fff 0.8px, transparent 0.8px),
    radial-gradient(circle at 20% 70%, #fff 0.6px, transparent 0.6px),
    radial-gradient(circle at 80% 60%, #fff 1.2px, transparent 1.2px),
    radial-gradient(circle at 60% 90%, #fff 0.4px, transparent 0.4px),
    /* ベースの宇宙色 */
    linear-gradient(135deg, #1e3c72 0%, #2a5298 25%, #1e3c72 50%, #0f0f23 75%, #000000 100%);
  
  background-size: 
    200% 200%, 200% 200%, 200% 200%,
    100px 100px, 150px 150px, 120px 120px, 80px 80px, 
    200px 200px, 90px 90px, 110px 110px, 60px 60px,
    100% 100%;
  
  /* キラキラアニメーション */
  animation: twinkle 8s ease-in-out infinite alternate;
  
  /* より深い宇宙感のための追加要素 */
  position: relative;
  overflow-x: hidden;
}

/* キラキラアニメーション */
@keyframes twinkle {
  0% {
    background-position: 
      0% 0%, 0% 0%, 0% 0%,
      0px 0px, 0px 0px, 0px 0px, 0px 0px,
      0px 0px, 0px 0px, 0px 0px, 0px 0px,
      0% 0%;
  }
  50% {
    background-position: 
      50% 50%, 80% 20%, 40% 80%,
      25px 25px, 35px 35px, 15px 15px, 45px 45px,
      55px 55px, 75px 75px, 65px 65px, 85px 85px,
      0% 0%;
  }
  100% {
    background-position: 
      100% 100%, 100% 100%, 100% 100%,
      50px 50px, 70px 70px, 30px 30px, 90px 90px,
      110px 110px, 150px 150px, 130px 130px, 170px 170px,
      0% 0%;
  }
}

/* 流れ星効果（疑似要素） */
#app::before {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    linear-gradient(45deg, transparent 30%, rgba(255, 255, 255, 0.5) 50%, transparent 70%);
  background-size: 20px 20px;
  animation: shooting-star 12s linear infinite;
  pointer-events: none;
  opacity: 0.3;
  z-index: -2;
}

@keyframes shooting-star {
  0% {
    transform: translateX(-100%) translateY(-100%);
    opacity: 0;
  }
  50% {
    opacity: 0.3;
  }
  100% {
    transform: translateX(100vw) translateY(100vh);
    opacity: 0;
  }
}

/* ネビュラ効果（もう一つの疑似要素） */
#app::after {
  content: '';
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: 
    radial-gradient(ellipse at center, rgba(138, 43, 226, 0.1) 0%, transparent 50%),
    radial-gradient(ellipse at 30% 70%, rgba(255, 20, 147, 0.1) 0%, transparent 50%),
    radial-gradient(ellipse at 70% 30%, rgba(0, 191, 255, 0.1) 0%, transparent 50%);
  animation: nebula-drift 15s ease-in-out infinite alternate;
  pointer-events: none;
  z-index: -1;
}

@keyframes nebula-drift {
  0% {
    transform: rotate(0deg) scale(1);
    opacity: 0.1;
  }
  50% {
    transform: rotate(2deg) scale(1.05);
    opacity: 0.2;
  }
  100% {
    transform: rotate(-2deg) scale(0.95);
    opacity: 0.15;
  }
}

.main-content {
  margin-top: 60px; /* MenuBarの高さ + 余白 */
  padding: 20px;
  position: relative;
  z-index: 1;
}

.game-controls {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 1rem;
  margin-bottom: 1rem;
}

/* 全体のテキスト色を宇宙テーマに調整 */
body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #E8E8FF;
  background-color: #000011; /* フォールバック色 */
}

/* HTMLとBODYにも宇宙背景を適用（完全カバレッジのため） */
html {
  background: 
    /* 銀河の渦巻き効果 */
    radial-gradient(ellipse at 20% 50%, rgba(120, 119, 198, 0.3) 0%, transparent 50%),
    radial-gradient(ellipse at 80% 20%, rgba(255, 119, 198, 0.3) 0%, transparent 50%),
    radial-gradient(ellipse at 40% 80%, rgba(120, 219, 255, 0.3) 0%, transparent 50%),
    /* 星の背景 */
    radial-gradient(circle at 25% 25%, #fff 1px, transparent 1px),
    radial-gradient(circle at 75% 75%, #fff 0.5px, transparent 0.5px),
    radial-gradient(circle at 90% 40%, #fff 1px, transparent 1px),
    radial-gradient(circle at 10% 80%, #fff 0.5px, transparent 0.5px),
    radial-gradient(circle at 50% 10%, #fff 0.8px, transparent 0.8px),
    radial-gradient(circle at 20% 70%, #fff 0.6px, transparent 0.6px),
    radial-gradient(circle at 80% 60%, #fff 1.2px, transparent 1.2px),
    radial-gradient(circle at 60% 90%, #fff 0.4px, transparent 0.4px),
    /* ベースの宇宙色 */
    linear-gradient(135deg, #1e3c72 0%, #2a5298 25%, #1e3c72 50%, #0f0f23 75%, #000000 100%);
  
  background-size: 
    200% 200%, 200% 200%, 200% 200%,
    100px 100px, 150px 150px, 120px 120px, 80px 80px, 
    200px 200px, 90px 90px, 110px 110px, 60px 60px,
    100% 100%;
  
  background-attachment: fixed;
  min-height: 100%;
}
</style>