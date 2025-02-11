<template>
  <div id="app">
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