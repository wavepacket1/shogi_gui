<template>
    <div class="branch-manager">    <div class="branch-header">      <button         class="tree-view-btn"        @click="showTreeViewer = true"        title="分岐ツリー構造を表示"      >        🌳 分岐ツリー表示      </button>    </div>

    <!-- 削除確認ダイアログ -->
    <div v-if="showDeleteDialog" class="dialog-overlay" @click="closeDeleteDialog">
      <div class="dialog" @click.stop>
        <div class="dialog-header">
          <h5>分岐削除の確認</h5>
          <button class="close-btn" @click="closeDeleteDialog">×</button>
        </div>
        
                <div class="dialog-body">          <p>分岐「<strong>{{ branchToDelete }}</strong>」を削除しますか？</p>        </div>
        
        <div class="dialog-footer">
          <button 
            class="cancel-btn"
            @click="closeDeleteDialog"
          >
            キャンセル
          </button>
          <button 
            class="delete-btn-confirm"
            @click="deleteBranch"
            :disabled="isDeleting"
          >
            {{ isDeleting ? '削除中...' : '削除' }}
          </button>
        </div>
      </div>
    </div>

    <!-- 分岐ツリー表示 -->
    <BranchTreeViewer
      v-if="showTreeViewer"
      :game-id="gameId"
      :current-branch="currentBranch"
      @close="showTreeViewer = false"
      @branch-switch="handleBranchSwitch"
    />
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import BranchTreeViewer from './BranchTreeViewer.vue'

interface Props {
  gameId: number
  currentBranch: string
  currentMoveNumber: number
  branches: string[]
}

interface Emits {
  (e: 'branchChanged', branch: string): void
  (e: 'branchCreated', branch: string): void
  (e: 'branchDeleted', branch: string): void
  (e: 'refreshBranches'): void
}

const props = defineProps<Props>()
const emit = defineEmits<Emits>()

// 状態管理
const showDeleteDialog = ref(false)
const showTreeViewer = ref(false)
const branchToDelete = ref('')
const isDeleting = ref(false)

// 分岐切り替え
const switchToBranch = async (branch: string) => {
  if (branch === props.currentBranch) return
  
  try {
    const response = await fetch(`/api/v1/games/${props.gameId}/switch_branch/${encodeURIComponent(branch)}`, {
      method: 'POST'
    })
    
    if (!response.ok) {
      const error = await response.json()
      alert(`分岐切り替えに失敗しました: ${error.error}`)
      return
    }
    
    const result = await response.json()
    emit('branchChanged', branch)
  } catch (error) {
    console.error('分岐切り替えエラー:', error)
    alert('分岐切り替えに失敗しました')
  }
}

// 分岐削除
const confirmDelete = (branch: string) => {
  branchToDelete.value = branch
  showDeleteDialog.value = true
}

const deleteBranch = async () => {
  if (!branchToDelete.value) return
  
  isDeleting.value = true
  
  try {
    const response = await fetch(`/api/v1/games/${props.gameId}/branches/${encodeURIComponent(branchToDelete.value)}`, {
      method: 'DELETE'
    })
    
    if (!response.ok) {
      const error = await response.json()
      alert(`分岐削除に失敗しました: ${error.error}`)
      return
    }
    
    const result = await response.json()
    
    // 削除された分岐が現在の分岐の場合はmainに切り替え
    if (branchToDelete.value === props.currentBranch) {
      await switchToBranch('main')
    }
    
    emit('branchDeleted', branchToDelete.value)
    emit('refreshBranches')
    closeDeleteDialog()
    
    alert(result.message)
  } catch (error) {
    console.error('分岐削除エラー:', error)
    alert('分岐削除に失敗しました')
  } finally {
    isDeleting.value = false
  }
}

// ツリービューアからの分岐切り替え
const handleBranchSwitch = async (branchName: string) => {
  showTreeViewer.value = false
  await switchToBranch(branchName)
}

// ダイアログ操作
const closeDeleteDialog = () => {
  showDeleteDialog.value = false
  branchToDelete.value = ''
}
</script>

<style scoped>
.branch-manager {  background: rgba(30, 30, 60, 0.9);  border-radius: 8px;  padding: 8px 12px;  margin-bottom: 8px;}.branch-header {  display: flex;  justify-content: center;  align-items: center;}

.tree-view-btn {
  background: #9C27B0;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 4px 8px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.tree-view-btn:hover {
  background: #7B1FA2;
  transform: scale(1.05);
}



/* ダイアログスタイル */
.dialog-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  justify-content: center;
  align-items: center;
  z-index: 1000;
}

.dialog {
  background: rgba(30, 30, 60, 0.95);
  border-radius: 8px;
  min-width: 400px;
  max-width: 500px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
}

.dialog-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
}

.dialog-header h5 {
  margin: 0;
  font-size: 16px;
  color: #E8E8FF;
}

.close-btn {
  background: none;
  border: none;
  font-size: 20px;
  cursor: pointer;
  padding: 0;
  width: 24px;
  height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #E8E8FF;
}

.dialog-body {
  padding: 20px;
  color: #E8E8FF;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 16px 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
}

.cancel-btn, .delete-btn-confirm {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s;
}

.cancel-btn {
  background: #f5f5f5;
  color: #333;
}

.cancel-btn:hover {
  background: #e9e9e9;
}

.delete-btn-confirm {
  background: #f44336;
  color: white;
}

.delete-btn-confirm:hover:not(:disabled) {
  background: #d32f2f;
}

.delete-btn-confirm:disabled {
  background: #ccc;
  cursor: not-allowed;
}

.warning {
  color: #f57c00;
  font-size: 13px;
  background: rgba(40, 40, 80, 0.6);
  padding: 8px;
  border-radius: 4px;
  border-left: 4px solid #f57c00;
}
</style> 