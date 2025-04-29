<template>
  <div class="mode-control">
    <label>モード:</label>
    <select v-model="currentMode" @change="onChangeMode">
      <option value="play">対局</option>
      <option value="edit">編集</option>
      <option value="study">検討</option>
    </select>
    <div class="settings">
      <label>
        <input type="checkbox" v-model="takeBackEnabled" disabled /> 待った機能
      </label>
      <span>上限: {{ maxTakeBacks }} 回</span>
      <span>タイムアウト: {{ takeBackTimeout }} 秒</span>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useBoardStore } from '@/store';

const boardStore      = useBoardStore();
const currentMode     = ref(boardStore.mode);
const takeBackEnabled = ref(boardStore.takeBackEnabled);
const maxTakeBacks    = ref(boardStore.maxTakeBacks);
const takeBackTimeout = ref(boardStore.takeBackTimeout);

onMounted(async () => {
  if (boardStore.game?.id) {
    await boardStore.fetchModeSettings(boardStore.game.id);
    currentMode.value = boardStore.mode;
  }
});

const onChangeMode = async () => {
  if (!boardStore.game) return;
  await boardStore.switchMode(boardStore.game.id, currentMode.value);
};
</script>

<style scoped>
.mode-control { display: flex; gap: 8px; align-items: center; }
.settings { margin-left: auto; font-size: 0.9em; }
</style> 