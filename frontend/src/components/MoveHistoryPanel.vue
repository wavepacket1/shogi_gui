<template>
  <div class="move-history-panel">
    <div class="panel-header">
      <h3>棋譜</h3>
      <div class="header-controls">
        <div class="branch-selector" v-if="branches.length > 1">
          <label for="branch-select">分岐:</label>
          <select id="branch-select" v-model="currentBranch" @change="onBranchChange">
            <option v-for="branch in branches" :key="branch" :value="branch">{{ branch }}</option>
          </select>
        </div>
      </div>
    </div>

    <!-- 分岐ツリービューア -->
    <BranchTreeViewer
      v-if="showTreeViewer"
      :game-id="gameId"
      :current-branch="currentBranch"
      @close="showTreeViewer = false"
      @branch-switch="onTreeViewerBranchSwitch"
    />

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
          
          <!-- +ボタン（代替手表示・分岐移動機能） -->
          <div 
            v-if="shouldShowPlusButton(history)" 
            class="alternative-moves-button"
          >
            <button 
              class="plus-button"
              @click.stop="toggleAlternativeMoves(index)"
              :title="`他分岐の手: ${getAlternativeMoves(history.move_number).length - 1}個`"
            >
              +
            </button>
            
            <!-- 代替手ドロップダウン -->
            <div 
              v-if="expandedMoveIndex === index" 
              class="alternative-moves-dropdown"
              @click.stop
            >
              <div class="alternative-moves-header">
                <span>代替手一覧</span>
                <button 
                  class="close-alternatives" 
                  @click="expandedMoveIndex = null"
                >
                  ×
                </button>
              </div>
              <div class="alternative-moves-list">
                <div 
                  v-for="altMove in getAlternativeMoves(history.move_number)"
                  :key="`${altMove.branch}-${altMove.move_number}`"
                  class="alternative-move-item"
                  @click="switchToAlternativeBranch(altMove.branch, altMove.move_number)"
                >
                  <span class="alt-move-notation">{{ formatMove(altMove) }}</span>
                  <span class="alt-move-branch">({{ altMove.branch }})</span>
                </div>
              </div>
            </div>
          </div>
          
          <!-- 分岐情報の表示（インジケータのみ） -->
          <div v-if="history.move_number > 0 && hasBranchesAtMove(history.move_number)" class="branch-info-indicator">
            <span class="branch-info-text" :title="`${getBranchCountAtMove(history.move_number)}つの分岐があります`">
              🌿 {{ getBranchCountAtMove(history.move_number) }}
            </span>
          </div>
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

<script setup lang="ts">
import { ref, computed, onMounted, watch, nextTick } from 'vue'
import { useBoardStore } from '@/store'
import { BoardHistory } from '@/store/types'
import CommentEditor from './CommentEditor.vue'
import BranchManager from './BranchManager.vue'
import BranchTreeViewer from './BranchTreeViewer.vue'

interface Props {
  gameId: number
  mode?: 'play' | 'edit' | 'study'
  allowEdit?: boolean
  showComments?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  mode: 'play',
  allowEdit: false,
  showComments: true
})

const boardStore = useBoardStore()
const boardHistories = ref<BoardHistory[]>([])
const branches = ref<string[]>(['main'])
const currentBranch = ref('main')
const currentMoveIndex = ref(-1)
const loading = ref(false)
const error = ref('')
const movesContainerRef = ref<HTMLElement | null>(null)

// 分岐関連の状態
const allBoardHistories = ref<BoardHistory[]>([])

// currentMoveIndexの変更を監視してスクロール処理を行う
watch(currentMoveIndex, (newIndex) => {
  if (newIndex >= 0) {
    nextTick(() => {
      scrollToCurrentMove()
    })
  }
})

// 棋譜リストの変更も監視して新しい手順が追加されたら自動スクロール
watch(boardHistories, (newHistories, oldHistories) => {
  if (newHistories.length > (oldHistories?.length || 0)) {
    // 新しい手順が追加された場合、最新の手順にスクロール
    nextTick(() => {
      scrollToLatestMove()
    })
  }
}, { deep: true })

// 現在の手順までスクロールする関数
const scrollToCurrentMove = () => {
  const container = movesContainerRef.value
  if (!container) return

  const activeMove = container.querySelector('.move-item.active') as HTMLElement
  if (activeMove) {
    const containerRect = container.getBoundingClientRect()
    const activeRect = activeMove.getBoundingClientRect()
    
    // アクティブな手順がコンテナの範囲外にある場合のみスクロール
    if (activeRect.top < containerRect.top || activeRect.bottom > containerRect.bottom) {
      activeMove.scrollIntoView({
        behavior: 'smooth',
        block: 'center'
      })
    }
  }
}

// 最新の手順までスクロールする関数
const scrollToLatestMove = () => {
  const container = movesContainerRef.value
  if (!container) return

  const moveItems = container.querySelectorAll('.move-item')
  if (moveItems.length > 0) {
    const lastMove = moveItems[moveItems.length - 1] as HTMLElement
    lastMove.scrollIntoView({
      behavior: 'smooth',
      block: 'end'
    })
  }
}

// 全分岐の履歴を取得
const fetchAllBoardHistories = async () => {
  console.log('📡 全分岐履歴の取得開始...', `gameId: ${props.gameId}`)
  const url = `http://localhost:3000/api/v1/games/${props.gameId}/board_histories/all_branches`
  console.log('🔗 Request URL:', url)
  
  try {
    const response = await fetch(url)
    console.log('📊 Response status:', response.status)
    
    if (response.ok) {
      const data = await response.json()
      allBoardHistories.value = data
      console.log('✅ 全分岐履歴取得成功:', {
        totalHistories: data.length,
        branches: [...new Set(data.map((h: any) => h.branch))],
        moveNumbers: [...new Set(data.map((h: any) => h.move_number))].sort((a: any, b: any) => a - b),
        firstFewRecords: data.slice(0, 3)
      })
    } else {
      console.warn('❌ 全分岐履歴取得失敗、フォールバックに切り替え')
      console.error('Failed to fetch all board histories:', response.status, response.statusText)
      // フォールバック処理に移行
      await fetchAllBoardHistoriesFallback()
    }
  } catch (err) {
    console.error('Error fetching all board histories:', err)
    // フォールバック: 各分岐を個別に取得
    await fetchAllBoardHistoriesFallback()
  }
}

// フォールバック: 各分岐を個別に取得
const fetchAllBoardHistoriesFallback = async () => {
  const allHistories: BoardHistory[] = []
  for (const branch of branches.value) {
    try {
      const branchResponse = await fetch(`http://localhost:3000/api/v1/games/${props.gameId}/board_histories?branch=${branch}`)
      if (branchResponse.ok) {
        const branchHistories = await branchResponse.json()
        allHistories.push(...branchHistories)
      }
    } catch (error) {
      console.error(`Error fetching histories for branch ${branch}:`, error)
    }
  }
  allBoardHistories.value = allHistories
  console.log('All board histories (fallback):', allBoardHistories.value.length)
}

// 分岐表示の改善：現在の分岐以外に同一手数の手があるかチェック
const hasBranchesAtMove = (moveNumber: number): boolean => {
  // 0手目は分岐なし
  if (moveNumber === 0) return false
  
  // 現在の分岐以外に同一手数の手が存在するかチェック
  const otherBranchMoves = allBoardHistories.value.filter(h => 
    h.move_number === moveNumber && h.branch !== currentBranch.value
  )
  
  const hasOtherMoves = otherBranchMoves.length > 0
  
  console.log(`📊 手数 ${moveNumber} 分岐判定:`, {
    currentBranch: currentBranch.value,
    otherBranchMoves: otherBranchMoves.map(h => ({
      branch: h.branch,
      notation: h.notation || h.move_sfen
    })),
    hasOtherMoves
  })
  
  return hasOtherMoves
}

// 分岐数を取得（改善版）
const getBranchCountAtMove = (moveNumber: number): number => {
  // 0手目は分岐数0
  if (moveNumber === 0) return 0
  
  // 現在の分岐以外の同一手数の手の数
  const otherBranchMoves = allBoardHistories.value.filter(h => 
    h.move_number === moveNumber && h.branch !== currentBranch.value
  )
  
  return otherBranchMoves.length
}

// 盤面履歴を取得
const fetchBoardHistories = async (preserveCurrentIndex: boolean = false) => {
  loading.value = true
  error.value = ''
  try {
    const response = await boardStore.fetchBoardHistories(props.gameId, currentBranch.value, preserveCurrentIndex)
    boardHistories.value = boardStore.boardHistories
    currentMoveIndex.value = boardStore.currentMoveIndex
  } catch (err) {
    error.value = '履歴の取得に失敗しました'
    console.error('Error fetching board histories:', err)
  } finally {
    loading.value = false
  }
}

// 分岐一覧を取得
const fetchBranches = async () => {
  try {
    const response = await boardStore.fetchBranches(props.gameId)
    branches.value = boardStore.branches
    console.log('🔄 分岐一覧取得完了:', branches.value)
    // 分岐情報更新後に全履歴を取得
    await fetchAllBoardHistories()
  } catch (err) {
    console.error('Error fetching branches:', err)
  }
}

// ストアの状態が変わったら再表示
watch(() => boardStore.boardHistories, () => {
  boardHistories.value = boardStore.boardHistories
})

// currentMoveIndexの変更を監視（ただし、手動で更新した場合は無視）
let isManualUpdate = false
watch(() => boardStore.currentMoveIndex, (newIndex) => {
  if (!isManualUpdate) {
    currentMoveIndex.value = newIndex
  }
  isManualUpdate = false
})

watch(() => boardStore.branches, () => {
  branches.value = boardStore.branches
})

watch(() => boardStore.currentBranch, () => {
  currentBranch.value = boardStore.currentBranch
})

// 特定の手数に移動
const navigateToMove = async (index: number) => {
  try {
    const history = boardHistories.value[index]
    if (!history) {
      console.error('History not found for index:', index)
      return
    }

    // 手動で現在の手数インデックスを更新
    currentMoveIndex.value = index
    isManualUpdate = true

    // 局面に移動
    await boardStore.navigateToMove({
      gameId: props.gameId,
      moveNumber: history.move_number
    })

    // 履歴を再取得（ハイライトの更新はコンポーネント側で行う）
    await boardStore.fetchBoardHistories(props.gameId, currentBranch.value, true)

    // 手動で現在の手数インデックスを更新（履歴の再取得後に設定）
    currentMoveIndex.value = index
  } catch (err) {
    console.error('Error navigating to move:', err)
  }
}

// 分岐変更時の処理
const onBranchChange = async () => {
  try {
    await boardStore.switchBranch({
      gameId: props.gameId,
      branchName: currentBranch.value
    })
    // ストアから最新の履歴を取得
    boardHistories.value = boardStore.boardHistories
    currentMoveIndex.value = boardStore.currentMoveIndex
  } catch (err) {
    console.error('Error switching branch:', err)
  }
}

// 分岐管理イベント処理
const onBranchChanged = async (branchName: string) => {
  currentBranch.value = branchName
  await fetchBoardHistories()
}

const onBranchCreated = (branchName: string) => {
  console.log(`新しい分岐が作成されました: ${branchName}`)
}

const onBranchDeleted = (branchName: string) => {
  console.log(`分岐が削除されました: ${branchName}`)
}

// 指し手の表示形式をフォーマット
const formatMove = (history: BoardHistory): string => {
  // 初期局面の処理
  if (history.move_number === 0) {
    return '開始局面'
  }
  
  // 優先順位:
  // 1. バックエンドから提供された棋譜表記
  if (history.notation) {
    return history.notation
  }
  
  // 2. move_sfenがある場合はそれを使用
  if (history.move_sfen) {
    // ここではシンプルに表示するだけ。より良いフォーマットは今後実装可能
    return `手: ${history.move_sfen}`
  }
  
  // フォールバック
  return `${history.move_number}手目`
}

// ナビゲーション用の関数を追加
const navigateToFirst = async () => {
  if (boardHistories.value.length > 0) {
    await navigateToMove(0)
  }
}

const navigateToPrev = async () => {
  if (currentMoveIndex.value > 0) {
    await navigateToMove(currentMoveIndex.value - 1)
  }
}

const navigateToNext = async () => {
  if (currentMoveIndex.value < boardHistories.value.length - 1) {
    await navigateToMove(currentMoveIndex.value + 1)
  }
}

const navigateToLast = async () => {
  if (boardHistories.value.length > 0) {
    await navigateToMove(boardHistories.value.length - 1)
  }
}

// 代替手の表示と分岐移動機能
const expandedMoveIndex = ref<number | null>(null)
const getAlternativeMoves = (moveNumber: number): BoardHistory[] => {
  // 0手目は代替手なし
  if (moveNumber === 0) return []
  
  // 現在の分岐以外の同一手数の手を取得
  return allBoardHistories.value.filter(history => 
    history.move_number === moveNumber && 
    history.branch !== currentBranch.value
  )
}

const toggleAlternativeMoves = (index: number) => {
  expandedMoveIndex.value = expandedMoveIndex.value === index ? null : index
}

const switchToAlternativeBranch = async (branch: string, moveNumber: number) => {
  try {
    await boardStore.switchBranch({
      gameId: props.gameId,
      branchName: branch
    })
    // ストアから最新の履歴を取得
    boardHistories.value = boardStore.boardHistories
    currentMoveIndex.value = boardStore.currentMoveIndex
  } catch (err) {
    console.error('Error switching branch:', err)
  }
}

// 分岐ツリービューア関連の状態と処理
const showTreeViewer = ref(false)
const onTreeViewerBranchSwitch = (branchName: string) => {
  currentBranch.value = branchName
  showTreeViewer.value = false
}

// +ボタン表示条件の判定（仕様書通り）
const shouldShowPlusButton = (history: BoardHistory): boolean => {
  // 0手目は表示しない（仕様書より）
  if (history.move_number === 0) {
    console.log('📝 0手目のため+ボタン非表示')
    return false
  }
  
  // 他分岐に同一手数の手が存在する場合のみ表示
  const alternativeMoves = getAlternativeMoves(history.move_number)
  const shouldShow = alternativeMoves.length > 0
  
  console.log(`📊 手数${history.move_number}の+ボタン判定:`, {
    moveNumber: history.move_number,
    alternativeMoves: alternativeMoves.length,
    shouldShow,
    alternatives: alternativeMoves.map(m => ({
      branch: m.branch,
      notation: m.notation
    }))
  })
  
  return shouldShow
}

// コンポーネントマウント時に履歴と分岐を取得
onMounted(async () => {
  console.log('🚀 MoveHistoryPanel初期化開始')
  // 順序を正しく設定: 分岐 → 履歴 → 全分岐データ
  await fetchBranches()
  await fetchBoardHistories()
  await fetchAllBoardHistories()
  console.log('✅ MoveHistoryPanel初期化完了')
})

// ゲームIDが変わったら再取得
watch(() => props.gameId, async () => {
  console.log('🎮 ゲームID変更:', props.gameId)
  await fetchBranches()
  await fetchBoardHistories()
  await fetchAllBoardHistories()
})
</script>

<style scoped>
.move-history-panel {
  width: 280px;
  height: 550px; /* 先手持ち駒エリアまでカバーする高さに設定 */
  max-height: 550px;
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

.header-controls {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
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
  position: relative;
}

.move-item:hover {
  background: rgba(60, 60, 120, 0.5);
  box-shadow: 0 2px 4px rgba(0,0,0,0.2);
  margin-left: 2px;
  z-index: auto;
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
  justify-content: space-between;
  position: relative;
}

.comment-section {
  margin-top: 4px;
}

/* 分岐情報インジケータのスタイル */
.branch-info-indicator {
  margin-left: auto;
}

.branch-info-text {
  color: rgba(76, 175, 80, 0.9);
  font-size: 12px;
  font-weight: bold;
  padding: 2px 6px;
  border-radius: 4px;
  background: rgba(76, 175, 80, 0.1);
  border: 1px solid rgba(76, 175, 80, 0.3);
  cursor: help;
  transition: all 0.2s ease;
}

.branch-info-text:hover {
  background: rgba(76, 175, 80, 0.2);
  border-color: rgba(76, 175, 80, 0.5);
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
      background: rgba(30, 30, 60, 0.95);
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

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .move-history-panel {
    width: 100%;
    max-width: 280px;
    height: 400px; /* タブレットでも少し高さを増やす */
    max-height: 400px;
  }
  
  .navigation-controls {
    padding: 6px;
    gap: 2px;
  }
  
  .nav-button {
    min-width: 28px;
    height: 24px;
    font-size: 12px;
  }
  
  .move-item {
    padding: 4px 6px;
    font-size: 13px;
  }

  .branch-dropdown {
    min-width: 180px;
  }
}

@media (max-width: 480px) {
  .move-history-panel {
    height: 300px; /* スマートフォンでも高さを増やす */
    max-height: 300px;
  }
  
  .move-item {
    padding: 3px 5px;
    font-size: 12px;
  }
  
  .moves-container::-webkit-scrollbar {
    width: 4px;
  }

  .branch-dropdown {
    min-width: 160px;
    right: -20px;
  }
}

/* +ボタン（代替手表示）のスタイル */
.alternative-moves-button {
  position: relative;
  margin-left: 8px;
  margin-right: 4px;
}

.plus-button {
  width: 20px;
  height: 20px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  background: rgba(74, 144, 226, 0.7);
  color: white;
  font-size: 12px;
  font-weight: bold;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

.plus-button:hover {
  background: rgba(74, 144, 226, 0.9);
  border-color: rgba(255, 255, 255, 0.5);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
  transform: scale(1.1);
}

/* 代替手ドロップダウンのスタイル */
.alternative-moves-dropdown {
  position: absolute;
  top: 25px;
  right: 0;
  min-width: 180px;
  background: rgba(30, 30, 60, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
  z-index: 1000;
  backdrop-filter: blur(5px);
}

.alternative-moves-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: rgba(40, 40, 80, 0.8);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 6px 6px 0 0;
  font-size: 12px;
  font-weight: bold;
  color: #E8E8FF;
}

.close-alternatives {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.7);
  font-size: 16px;
  cursor: pointer;
  padding: 0;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.close-alternatives:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.alternative-moves-list {
  max-height: 150px;
  overflow-y: auto;
}

.alternative-move-item {
  padding: 8px 12px;
  cursor: pointer;
  transition: all 0.2s ease;
  border-bottom: 1px solid rgba(255, 255, 255, 0.05);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.alternative-move-item:hover {
  background: rgba(74, 144, 226, 0.3);
}

.alternative-move-item:last-child {
  border-bottom: none;
}

.alt-move-notation {
  font-family: 'Courier New', monospace;
  font-weight: 500;
  color: #E8E8FF;
  font-size: 13px;
}

.alt-move-branch {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.6);
  background: rgba(74, 144, 226, 0.2);
  padding: 2px 6px;
  border-radius: 3px;
  border: 1px solid rgba(74, 144, 226, 0.3);
}
</style> 