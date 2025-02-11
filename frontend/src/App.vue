<template>
  <div id="app">
    <h1>将棋GUI</h1>
    <button @click="startGame">対局開始</button> 
    <ShogiBoard />
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import ShogiBoard from './components/ShogiBoard.vue';
import { useBoardStore } from '@/store';

export default defineComponent({
  name: 'App',
  components: {
    ShogiBoard,
  },
  setup() {
    const boardStore = useBoardStore();

    const startGame = async () => {
      await boardStore.createGame();
    };

    return {
      startGame,
    };
  },
});
</script>

<style>
#app {
  text-align: center;
  margin-top: 50px;
}
</style>