<template>
  <div class="branch-manager">
    <div class="branch-header">
      <h4>分岐管理</h4>
      <button 
        class="create-branch-btn"
        @click="showCreateDialog = true"
        :disabled="!canCreateBranch"
        title="現在の局面から新しい分岐を作成"
      >
        + 分岐作成
      </button>
    </div>

    <!-- 分岐一覧 -->
    <div class="branch-list">
      <div 
        v-for="branch in branches" 
        :key="branch"
        :class="['branch-item', { 'active': branch === currentBranch }]"
        @click="switchToBranch(branch)"
      >
        <div class="branch-info">
          <span class="branch-name">{{ branch }}</span>
          <span v-if="branch === 'main'" class="main-badge">メイン</span>
        </div>
        
        <div class="branch-actions">
          <button 
            v-if="branch !== 'main'"
            class="delete-btn"
            @click.stop="confirmDelete(branch)"
            title="分岐を削除"
          >
            🗑️
          </button>
        </div>
      </div>
    </div>

    <!-- 分岐作成ダイアログ -->
    <div v-if="showCreateDialog" class="dialog-overlay" @click="closeCreateDialog">
      <div class="dialog" @click.stop>
        <div class="dialog-header">
          <h5>新しい分岐を作成</h5>
          <button class="close-btn" @click="closeCreateDialog">×</button>
        </div>
        
        <div class="dialog-body">
          <div class="form-group">
            <label for="branch-name">分岐名:</label>
            <input
              id="branch-name"
              v-model="newBranchName"
              type="text"
              placeholder="例: my-variation"
              pattern="[a-zA-Z0-9_-]+"
              :class="{ 'error': branchNameError }"
            />
            <div v-if="branchNameError" class="error-message">
              {{ branchNameError }}
            </div>
            <div class="help-text">
              英数字、ハイフン(-)、アンダースコア(_)のみ使用可能
            </div>
          </div>

          <div class="form-group">
            <label>分岐開始地点:</label>
            <div class="branch-point">
              手数 {{ currentMoveNumber }} から分岐
            </div>
          </div>
        </div>
        
        <div class="dialog-footer">
          <button 
            class="cancel-btn"
            @click="closeCreateDialog"
          >
            キャンセル
          </button>
          <button 
            class="create-btn"
            @click="createBranch"
            :disabled="!isValidBranchName || isCreating"
          >
            {{ isCreating ? '作成中...' : '作成' }}
          </button>
        </div>
      </div>
    </div>

    <!-- 削除確認ダイアログ -->
    <div v-if="showDeleteDialog" class="dialog-overlay" @click="closeDeleteDialog">
      <div class="dialog" @click.stop>
        <div class="dialog-header">
          <h5>分岐削除の確認</h5>
          <button class="close-btn" @click="closeDeleteDialog">×</button>
        </div>
        
        <div class="dialog-body">
          <p>分岐「<strong>{{ branchToDelete }}</strong>」を削除しますか？</p>
          <p class="warning">
            ⚠️ この操作は元に戻せません。分岐に含まれる全ての手順とコメントが削除されます。
          </p>
        </div>
        
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
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'

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
const showCreateDialog = ref(false)
const showDeleteDialog = ref(false)
const newBranchName = ref('')
const branchToDelete = ref('')
const isCreating = ref(false)
const isDeleting = ref(false)
const branchNameError = ref('')

// 計算プロパティ
const canCreateBranch = computed(() => {
  return props.currentMoveNumber >= 0
})

const isValidBranchName = computed(() => {
  const name = newBranchName.value.trim()
  if (!name) return false
  
  // 英数字、ハイフン、アンダースコアのみ許可
  const pattern = /^[a-zA-Z0-9_-]+$/
  if (!pattern.test(name)) {
    branchNameError.value = '英数字、ハイフン(-)、アンダースコア(_)のみ使用できます'
    return false
  }
  
  // 既存の分岐名と重複チェック
  if (props.branches.includes(name)) {
    branchNameError.value = 'この分岐名は既に存在します'
    return false
  }
  
  branchNameError.value = ''
  return true
})

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

// 分岐作成
const createBranch = async () => {
  if (!isValidBranchName.value) return
  
  isCreating.value = true
  
  try {
    const response = await fetch(`/api/v1/games/${props.gameId}/board_histories/${props.currentMoveNumber}/branches`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        branch_name: newBranchName.value.trim(),
        source_branch: props.currentBranch
      })
    })
    
    if (!response.ok) {
      const error = await response.json()
      branchNameError.value = error.error || '分岐作成に失敗しました'
      return
    }
    
    const result = await response.json()
    
    // 成功時の処理
    emit('branchCreated', result.branch_name)
    emit('refreshBranches')
    closeCreateDialog()
    
    // 新しい分岐に切り替え
    await switchToBranch(result.branch_name)
  } catch (error) {
    console.error('分岐作成エラー:', error)
    branchNameError.value = '分岐作成に失敗しました'
  } finally {
    isCreating.value = false
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

// ダイアログ操作
const closeCreateDialog = () => {
  showCreateDialog.value = false
  newBranchName.value = ''
  branchNameError.value = ''
}

const closeDeleteDialog = () => {
  showDeleteDialog.value = false
  branchToDelete.value = ''
}

// 入力監視
const watchBranchName = () => {
  // バリデーション実行のために計算プロパティを参照
  isValidBranchName.value
}

onMounted(() => {
  // 必要に応じて初期化処理
})
</script>

<style scoped>
.branch-manager {
  background: rgba(30, 30, 60, 0.9);
  border-radius: 8px;
  padding: 12px;
  margin-bottom: 8px;
}

.branch-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.branch-header h4 {
  margin: 0;
  color: #E8E8FF;
  font-size: 14px;
  font-weight: bold;
}

.create-branch-btn {
  background: #4CAF50;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 4px 8px;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.2s;
}

.create-branch-btn:hover:not(:disabled) {
  background: #45a049;
}

.create-branch-btn:disabled {
  background: #666;
  cursor: not-allowed;
}

.branch-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.branch-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 8px;
  border-radius: 4px;
  cursor: pointer;
  transition: all 0.2s;
  background: rgba(40, 40, 80, 0.5);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.branch-item:hover {
  background: rgba(60, 60, 120, 0.6);
}

.branch-item.active {
  background: rgba(74, 144, 226, 0.7);
  border-color: rgba(74, 144, 226, 0.9);
}

.branch-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.branch-name {
  color: #E8E8FF;
  font-size: 13px;
}

.main-badge {
  background: #FF9800;
  color: white;
  font-size: 10px;
  padding: 2px 4px;
  border-radius: 2px;
}

.branch-actions {
  display: flex;
  gap: 4px;
}

.delete-btn {
  background: none;
  border: none;
  font-size: 12px;
  cursor: pointer;
  opacity: 0.7;
  transition: opacity 0.2s;
}

.delete-btn:hover {
  opacity: 1;
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
  border-bottom: 1px solid #eee;
}

.dialog-header h5 {
  margin: 0;
  font-size: 16px;
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
}

.dialog-body {
  padding: 20px;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 4px;
  font-weight: bold;
  font-size: 14px;
}

.form-group input {
  width: 100%;
  padding: 8px 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  font-size: 14px;
  box-sizing: border-box;
}

.form-group input.error {
  border-color: #f44336;
}

.error-message {
  color: #f44336;
  font-size: 12px;
  margin-top: 4px;
}

.help-text {
  color: #666;
  font-size: 12px;
  margin-top: 4px;
}

.branch-point {
  background: #f5f5f5;
  padding: 8px;
  border-radius: 4px;
  font-size: 14px;
}

.dialog-footer {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  padding: 16px 20px;
  border-top: 1px solid #eee;
}

.cancel-btn, .create-btn, .delete-btn-confirm {
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

.create-btn {
  background: #4CAF50;
  color: white;
}

.create-btn:hover:not(:disabled) {
  background: #45a049;
}

.create-btn:disabled {
  background: #ccc;
  cursor: not-allowed;
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