<template>
  <div class="move-history-panel">
    <div class="panel-header">
      <h3>棋譜</h3>
      <div class="branch-selector" v-if="branches.length > 1">
        <label for="branch-select">分岐:</label>
        <select id="branch-select" v-model="currentBranch" @change="onBranchChange">
          <option v-for="branch in branches" :key="branch" :value="branch">{{ branch }}</option>
        </select>
      </div>
    </div>
    
    <!-- 棋譜操作ボタンを追加 -->
    <div class="navigation-controls">
      <button 
        class="nav-button"
        @click="navigateToFirst()"
        :disabled="currentMoveIndex <= 0"
        title="最初の局面"
      >
        |◀
      </button>
      <button 
        class="nav-button"
        @click="navigateToPrev()"
        :disabled="currentMoveIndex <= 0"
        title="一手戻る"
      >
        ◀
      </button>
      <button 
        class="nav-button"
        @click="navigateToNext()"
        :disabled="currentMoveIndex >= boardHistories.length - 1"
        title="一手進む"
      >
        ▶
      </button>
      <button 
        class="nav-button"
        @click="navigateToLast()"
        :disabled="currentMoveIndex >= boardHistories.length - 1"
        title="最後の局面"
      >
        ▶|
      </button>
    </div>
    
    <div class="moves-container" ref="movesContainerRef">
      <div 
        v-for="(history, index) in boardHistories" 
        :key="index"
        :class="['move-item', { 'active': currentMoveIndex === index }]"
        @click="navigateToMove(index)"
        :ref="index === currentMoveIndex ? 'activeMove' : undefined"
      >
        <span class="move-number">{{ index }}.</span>
        <span class="move-notation">{{ formatMove(history) }}</span>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, onMounted, watch, nextTick } from 'vue';
import { useBoardStore } from '@/store';
import { BoardHistory } from '@/store/types';

export default defineComponent({
  name: 'MoveHistoryPanel',
  props: {
    gameId: {
      type: Number,
      required: true
    }
  },
  setup(props) {
    const boardStore = useBoardStore();
    const boardHistories = ref<BoardHistory[]>([]);
    const branches = ref<string[]>(['main']);
    const currentBranch = ref('main');
    const currentMoveIndex = ref(-1);
    const loading = ref(false);
    const error = ref('');
    const movesContainerRef = ref<HTMLElement | null>(null);

    // currentMoveIndexの変更を監視してスクロール処理を行う
    watch(currentMoveIndex, (newIndex) => {
      if (newIndex >= 0) {
        nextTick(() => {
          const activeMove = document.querySelector('.move-item.active');
          if (activeMove && movesContainerRef.value) {
            activeMove.scrollIntoView({
              behavior: 'smooth',
              block: 'center'
            });
          }
        });
      }
    });

    // 盤面履歴を取得
    const fetchBoardHistories = async (preserveCurrentIndex: boolean = false) => {
      loading.value = true;
      error.value = '';
      try {
        const response = await boardStore.fetchBoardHistories(props.gameId, currentBranch.value, preserveCurrentIndex);
        boardHistories.value = boardStore.boardHistories;
        currentMoveIndex.value = boardStore.currentMoveIndex;
      } catch (err) {
        error.value = '履歴の取得に失敗しました';
        console.error('Error fetching board histories:', err);
      } finally {
        loading.value = false;
      }
    };

    // 分岐一覧を取得
    const fetchBranches = async () => {
      try {
        const response = await boardStore.fetchBranches(props.gameId);
        branches.value = boardStore.branches;
      } catch (err) {
        console.error('Error fetching branches:', err);
      }
    };

    // ストアの状態が変わったら再表示
    watch(() => boardStore.boardHistories, () => {
      boardHistories.value = boardStore.boardHistories;
    });

    // currentMoveIndexの変更を監視（ただし、手動で更新した場合は無視）
    let isManualUpdate = false;
    watch(() => boardStore.currentMoveIndex, (newIndex) => {
      if (!isManualUpdate) {
        currentMoveIndex.value = newIndex;
      }
      isManualUpdate = false;
    });

    watch(() => boardStore.branches, () => {
      branches.value = boardStore.branches;
    });

    watch(() => boardStore.currentBranch, () => {
      currentBranch.value = boardStore.currentBranch;
    });

    // 特定の手数に移動
    const navigateToMove = async (index: number) => {
      try {
        const history = boardHistories.value[index];
        if (!history) {
          console.error('History not found for index:', index);
          return;
        }

        // 手動で現在の手数インデックスを更新
        currentMoveIndex.value = index;
        isManualUpdate = true;

        // 局面に移動
        await boardStore.navigateToMove({
          gameId: props.gameId,
          moveNumber: history.move_number
        });

        // 履歴を再取得（ハイライトの更新はコンポーネント側で行う）
        await boardStore.fetchBoardHistories(props.gameId, currentBranch.value, true);

        // 手動で現在の手数インデックスを更新（履歴の再取得後に設定）
        currentMoveIndex.value = index;
      } catch (err) {
        console.error('Error navigating to move:', err);
      }
    };

    // 分岐変更時の処理
    const onBranchChange = async () => {
      try {
        await boardStore.switchBranch({
          gameId: props.gameId,
          branchName: currentBranch.value
        });
        // ストアから最新の履歴を取得
        boardHistories.value = boardStore.boardHistories;
        currentMoveIndex.value = boardStore.currentMoveIndex;
      } catch (err) {
        console.error('Error switching branch:', err);
      }
    };

    // 指し手の表示形式をフォーマット
    const formatMove = (history: BoardHistory): string => {
      // 初期局面の処理
      if (history.move_number === 0) {
        return '開始局面';
      }
      
      // 優先順位:
      // 1. バックエンドから提供された棋譜表記
      if (history.notation) {
        return history.notation;
      }
      
      // 2. move_sfenがある場合はそれを使用
      if (history.move_sfen) {
        // ここではシンプルに表示するだけ。より良いフォーマットは今後実装可能
        return `手: ${history.move_sfen}`;
      }
      
      // フォールバック
      return `${history.move_number}手目`;
    };

    // コンポーネントマウント時に履歴と分岐を取得
    onMounted(() => {
      fetchBoardHistories();
      fetchBranches();
    });

    // ゲームIDが変わったら再取得
    watch(() => props.gameId, () => {
      fetchBoardHistories();
      fetchBranches();
    });

    // ナビゲーション用の関数を追加
    const navigateToFirst = async () => {
      if (boardHistories.value.length > 0) {
        await navigateToMove(0);
      }
    };

    const navigateToPrev = async () => {
      if (currentMoveIndex.value > 0) {
        await navigateToMove(currentMoveIndex.value - 1);
      }
    };

    const navigateToNext = async () => {
      if (currentMoveIndex.value < boardHistories.value.length - 1) {
        await navigateToMove(currentMoveIndex.value + 1);
      }
    };

    const navigateToLast = async () => {
      if (boardHistories.value.length > 0) {
        await navigateToMove(boardHistories.value.length - 1);
      }
    };

    return {
      boardHistories,
      branches,
      currentBranch,
      currentMoveIndex,
      loading,
      error,
      navigateToMove,
      onBranchChange,
      formatMove,
      navigateToFirst,
      navigateToPrev,
      navigateToNext,
      navigateToLast,
      movesContainerRef
    };
  }
});
</script>

<style scoped>
.move-history-panel {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  border: 1px solid #ccc;
  border-radius: 4px;
  overflow: hidden;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background-color: #f5f5f5;
  border-bottom: 1px solid #ccc;
}

.panel-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: bold;
}

.branch-selector {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
}

.branch-selector select {
  padding: 2px 4px;
  border-radius: 3px;
  border: 1px solid #ccc;
}

.moves-container {
  flex: 1;
  overflow-y: auto;
  padding: 8px;
  background-color: #fff;
}

.move-item {
  display: flex;
  padding: 6px 8px;
  cursor: pointer;
  border-radius: 4px;
  margin-bottom: 4px;
  transition: background-color 0.2s;
}

.move-item:hover {
  background-color: #f0f0f0;
}

.move-item.active {
  background-color: #e3f2fd;
  font-weight: bold;
  border-left: 3px solid #1976d2;
}

.move-number {
  width: 30px;
  color: #666;
  font-weight: normal;
}

.move-notation {
  flex: 1;
}

.navigation-controls {
  display: flex;
  justify-content: center;
  gap: 4px;
  padding: 8px;
  background-color: #f5f5f5;
  border-bottom: 1px solid #ccc;
}

.nav-button {
  min-width: 32px;
  height: 28px;
  padding: 0 8px;
  border: 1px solid #ccc;
  border-radius: 4px;
  background-color: #fff;
  color: #1976d2;  /* パネルの青色に合わせる */
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.nav-button:hover:not(:disabled) {
  background-color: #e3f2fd;  /* アクティブな項目の背景色と同じ */
  border-color: #1976d2;
}

.nav-button:active:not(:disabled) {
  background-color: #bbdefb;
  transform: translateY(1px);
  box-shadow: none;
}

.nav-button:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  background-color: #f5f5f5;
  border-color: #ddd;
  color: #999;
}
</style>