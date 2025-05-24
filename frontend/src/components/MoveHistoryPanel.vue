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

    <!-- 検討モード時のみ分岐管理UIを表示 -->
    <BranchManager
      v-if="mode === 'study'"
      :game-id="gameId"
      :current-branch="currentBranch"
      :current-move-number="currentMoveIndex"
      :branches="branches"
      @branch-changed="onBranchChanged"
      @branch-created="onBranchCreated"
      @branch-deleted="onBranchDeleted"
      @refresh-branches="fetchBranches"
    />
    
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
        <div class="move-content">
          <span class="move-number">{{ index }}.</span>
          <span class="move-notation">{{ formatMove(history) }}</span>
        </div>
        
        <!-- 検討モードの場合のみコメント機能を表示 -->
        <div v-if="mode === 'study' && showComments" class="comment-section">
          <CommentEditor
            :game-id="gameId"
            :move-number="history.move_number"
            :board-history-id="history.id"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import { defineComponent, ref, computed, onMounted, watch, nextTick } from 'vue';
import { useBoardStore } from '@/store';
import { BoardHistory } from '@/store/types';
import CommentEditor from './CommentEditor.vue';
import BranchManager from './BranchManager.vue';
import type { GameMode } from '@/types/shogi';

export interface MoveHistoryPanelProps {
  gameId: number;
  mode: GameMode;
  allowEdit?: boolean;
  showComments?: boolean;
}

export default defineComponent({
  name: 'MoveHistoryPanel',
  components: {
    CommentEditor,
    BranchManager
  },
  props: {
    gameId: {
      type: Number,
      required: true
    },
    mode: {
      type: String as () => GameMode,
      default: 'play'
    },
    allowEdit: {
      type: Boolean,
      default: false
    },
    showComments: {
      type: Boolean,
      default: true
    }
  },
  setup(props: MoveHistoryPanelProps) {
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

    // 分岐管理イベント処理
    const onBranchChanged = async (branchName: string) => {
      currentBranch.value = branchName;
      await fetchBoardHistories();
    };

    const onBranchCreated = (branchName: string) => {
      console.log(`新しい分岐が作成されました: ${branchName}`);
    };

    const onBranchDeleted = (branchName: string) => {
      console.log(`分岐が削除されました: ${branchName}`);
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
      onBranchChanged,
      onBranchCreated,
      onBranchDeleted,
      fetchBranches,
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
  width: 280px;
  height: 100%;
  border: none;
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  background: rgba(30, 30, 60, 0.9);
  backdrop-filter: blur(15px);
  box-shadow: 
    0 4px 8px rgba(0,0,0,0.2),
    0 0 20px rgba(138, 43, 226, 0.1),
    inset 0 1px 0 rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.panel-header {
  background: rgba(40, 40, 80, 0.8);
  color: #E8E8FF;
  padding: 8px 12px;
  text-align: center;
  font-weight: bold;
  font-size: 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  text-shadow: 0 0 5px rgba(255, 255, 255, 0.3);
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
  background: rgba(25, 25, 50, 0.5);
}

.move-item {
  padding: 6px 8px;
  margin-bottom: 2px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-size: 14px;
  color: #E8E8FF;
  background: rgba(40, 40, 80, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.05);
  text-shadow: 0 0 3px rgba(255, 255, 255, 0.2);
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.move-item:hover {
  background: rgba(60, 60, 120, 0.5);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  transform: translateX(2px);
}

.move-item.active {
  background: rgba(74, 144, 226, 0.6);
  color: white;
  font-weight: bold;
  box-shadow: 
    0 2px 4px rgba(0,0,0,0.3),
    0 0 10px rgba(74, 144, 226, 0.4);
  border: 1px solid rgba(74, 144, 226, 0.8);
}

.move-number {
  width: 30px;
  color: #666;
  font-weight: normal;
}

.move-notation {
  font-family: 'Courier New', monospace;
  font-weight: 500;
}

.move-content {
  display: flex;
  align-items: center;
}

.comment-section {
  margin-top: 4px;
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

/* スクロールバーのスタイル */
.moves-container::-webkit-scrollbar {
  width: 6px;
}

.moves-container::-webkit-scrollbar-track {
  background: rgba(40, 40, 80, 0.3);
  border-radius: 3px;
}

.moves-container::-webkit-scrollbar-thumb {
  background: rgba(74, 144, 226, 0.6);
  border-radius: 3px;
}

.moves-container::-webkit-scrollbar-thumb:hover {
  background: rgba(74, 144, 226, 0.8);
}
</style>