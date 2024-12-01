<template>
  <div id="app">
    <h1>将棋盤</h1>
    <ShogiBoard />
  </div>
</template>

<script lang="ts">
import { defineComponent } from 'vue';
import ShogiBoard from './components/ShogiBoard.vue';

export default defineComponent({
  name: 'App',
  components: {
    ShogiBoard,
  },
});
</script>

<style>
#app {
  text-align: center;
  margin-top: 50px;
}
</style>