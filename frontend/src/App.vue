<template>
  <div id="app">
    <!-- <MenuBar /> -->
    <ShogiBoard />
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
  },
});
</script>

<style>
#app {
  text-align: center;
  margin-top: 50px;
  user-select: none;        
  -webkit-user-select: none;
}

.game-controls {
  display: flex;
  gap: 1rem;
  justify-content: center;
  margin-top: 1rem;
  margin-bottom: 1rem;
}
</style>