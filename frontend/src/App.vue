<template>
  <div id="app">
    <MenuBar />
    <div class="main-content">
      <ShogiBoard />
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import ShogiBoard from './components/ShogiBoard.vue';
import MenuBar from './components/MenuBar.vue';

export default defineComponent({
  name: 'App',
  components: {
    ShogiBoard,
    MenuBar,
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