<template>
  <div class="comment-editor">
    <div class="comment-header">
      <button 
        class="comment-toggle-btn"
        @click="toggleEditor"
        :class="{ 'has-comments': hasComments, 'panel-open': isEditorOpen }"
      >
        <svg class="comment-icon" viewBox="0 0 24 24" width="16" height="16">
          <path d="M20 2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h14l4 4V4c0-1.1-.9-2-2-2z"/>
        </svg>
        <span class="comment-count" v-if="comments.length > 0">{{ comments.length }}</span>
      </button>
    </div>

    <div v-if="isEditorOpen" class="comment-editor-panel">
      <!-- パネルヘッダー -->
      <div class="comment-panel-header">
        <span class="panel-title">コメント</span>
        <button class="close-panel-btn" @click="closeEditor" title="閉じる">
          <svg viewBox="0 0 24 24" width="16" height="16">
            <path d="M18.3 5.71a.996.996 0 0 0-1.41 0L12 10.59 7.11 5.7A.996.996 0 1 0 5.7 7.11L10.59 12 5.7 16.89a.996.996 0 1 0 1.41 1.41L12 13.41l4.89 4.89a.996.996 0 0 0 1.41-1.41L13.41 12l4.89-4.89c.38-.38.38-1.02 0-1.4z"/>
          </svg>
        </button>
      </div>

      <!-- 既存コメント一覧 -->
      <div v-if="comments.length > 0" class="comment-list">
        <div 
          v-for="comment in comments" 
          :key="comment.id"
          class="comment-item"
        >
          <div v-if="!studyStore.isEditing(comment.id)" class="comment-display">
            <div class="comment-content">{{ comment.content }}</div>
            <div class="comment-meta">
              <span class="comment-date">{{ formatDate(comment.updated_at) }}</span>
              <button 
                class="edit-btn"
                @click="startEdit(comment.id, comment.content)"
              >
                編集
              </button>
              <button 
                class="delete-btn"
                @click="deleteComment(comment.id)"
              >
                削除
              </button>
            </div>
          </div>

          <div v-else class="comment-edit">
            <textarea
              v-model="editingContent"
              ref="editTextarea"
              class="comment-textarea"
              placeholder="コメントを入力してください..."
              :maxlength="maxLength"
              @input="onEditInput(comment.id)"
            />
            <div class="comment-edit-footer">
              <span class="char-count">{{ editingContent.length }}/{{ maxLength }}</span>
              <div class="edit-buttons">
                <button 
                  class="save-btn"
                  @click="saveEdit(comment.id)"
                  :disabled="editingContent.trim().length === 0"
                >
                  保存
                </button>
                <button 
                  class="cancel-btn"
                  @click="cancelEdit"
                >
                  キャンセル
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 新規コメント作成 -->
      <div v-if="!isCreating && studyStore.editingCommentId === null" class="comment-create">
        <button 
          class="add-comment-btn"
          @click="startCreate"
        >
          + コメントを追加
        </button>
      </div>

      <div v-if="isCreating" class="comment-new">
        <textarea
          v-model="newCommentContent"
          ref="newTextarea"
          class="comment-textarea"
          placeholder="コメントを入力してください..."
          :maxlength="maxLength"
          @keydown.enter.ctrl="createComment"
          @keydown.escape="cancelCreate"
        />
        <div class="comment-new-footer">
          <span class="char-count">{{ newCommentContent.length }}/{{ maxLength }}</span>
          <div class="new-buttons">
            <button 
              class="save-btn"
              @click="createComment"
              :disabled="newCommentContent.trim().length === 0"
            >
              作成
            </button>
            <button 
              class="cancel-btn"
              @click="cancelCreate"
            >
              キャンセル
            </button>
          </div>
        </div>
      </div>

      <!-- ローディング表示 -->
      <div v-if="studyStore.isLoadingComments" class="loading">
        読み込み中...
      </div>

      <!-- 成功メッセージ -->
      <div v-if="showSuccessMessage" class="success-message">
        ✅ コメントが作成されました
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick, onUnmounted } from 'vue'
import { useStudyModeStore } from '@/stores/studyMode'
import type { Comment } from '@/types/shogi'

interface Props {
  gameId: number
  moveNumber: number
  boardHistoryId: string | number
}

const props = defineProps<Props>()
const studyStore = useStudyModeStore()

// 状態管理
const isEditorOpen = ref(false)
const isCreating = ref(false)
const newCommentContent = ref('')
const editingContent = ref('')
const maxLength = 1000
const showSuccessMessage = ref(false)

// 参照
const editTextarea = ref<HTMLTextAreaElement>()
const newTextarea = ref<HTMLTextAreaElement>()

// 計算プロパティ
const comments = computed(() => studyStore.getCommentsForMove(props.boardHistoryId))
const hasComments = computed(() => studyStore.hasComments(props.boardHistoryId))

// エディター表示切り替え
const toggleEditor = async () => {
  if (isEditorOpen.value) {
    // エディターを閉じる際に状態をリセット
    closeEditor()
  } else {
    // エディターを開く
    isEditorOpen.value = true
    
    // エディターを開く際は常にコメントを最新取得
    try {
      await studyStore.fetchComments(props.gameId, props.moveNumber)
    } catch (error) {
      console.error('コメント取得に失敗しました:', error)
    }
  }
}

// エディターを閉じる処理
const closeEditor = () => {
  isEditorOpen.value = false
  isCreating.value = false
  newCommentContent.value = ''
  studyStore.stopEditing()
  editingContent.value = ''
  showSuccessMessage.value = false
}

// 新規コメント作成
const startCreate = async () => {
  isCreating.value = true
  newCommentContent.value = ''
  
  await nextTick()
  newTextarea.value?.focus()
}

const createComment = async () => {
  if (newCommentContent.value.trim().length === 0) return
  
  try {
    await studyStore.createComment(props.gameId, props.moveNumber, newCommentContent.value.trim())
    newCommentContent.value = ''
    isCreating.value = false
    
    // 成功メッセージを表示
    showSuccessMessage.value = true
    
    // 作成されたコメントが表示されてから自動クローズ
    setTimeout(() => {
      showSuccessMessage.value = false
      
      // さらに少し待ってから閉じる（ユーザーがコメントを確認できる時間を確保）
      setTimeout(() => {
        closeEditor()
      }, 2000) // 2秒後に閉じる
    }, 1500) // 成功メッセージを1.5秒表示
    
  } catch (error) {
    console.error('コメント作成に失敗しました:', error)
    alert('コメントの作成に失敗しました')
  }
}

const cancelCreate = () => {
  isCreating.value = false
  newCommentContent.value = ''
}

// コメント編集
const startEdit = async (commentId: number, content: string) => {
  studyStore.startEditing(commentId)
  editingContent.value = content
  
  await nextTick()
  editTextarea.value?.focus()
}

const saveEdit = async (commentId: number) => {
  if (editingContent.value.trim().length === 0) return
  
  try {
    await studyStore.updateComment(props.gameId, props.moveNumber, commentId, editingContent.value.trim())
    studyStore.stopEditing()
    editingContent.value = ''
  } catch (error) {
    console.error('コメント更新に失敗しました:', error)
    alert('コメントの更新に失敗しました')
  }
}

const cancelEdit = () => {
  studyStore.stopEditing()
  editingContent.value = ''
}

// 自動保存（編集時）
const onEditInput = (commentId: number) => {
  if (editingContent.value.trim().length > 0) {
    studyStore.scheduleAutoSave(props.gameId, props.moveNumber, commentId, editingContent.value.trim())
  }
}

// コメント削除
const deleteComment = async (commentId: number) => {
  try {
    await studyStore.deleteComment(props.gameId, props.moveNumber, commentId)
  } catch (error) {
    console.error('コメント削除に失敗しました:', error)
    alert('コメントの削除に失敗しました')
  }
}

// 日付フォーマット
const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  return date.toLocaleString('ja-JP', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  })
}

// ESCキーでエディターを閉じる
const handleEscape = (event: KeyboardEvent) => {
  if (event.key === 'Escape' && isEditorOpen.value) {
    closeEditor()
  }
}

// マウント時の設定
onMounted(() => {
  studyStore.setCurrentGame(props.gameId, props.moveNumber)
  document.addEventListener('keydown', handleEscape)
})

// アンマウント時のクリーンアップ
onUnmounted(() => {
  document.removeEventListener('keydown', handleEscape)
})
</script>

<style scoped>
.comment-editor {
  position: relative;
  z-index: 1;
  width: 100%;
}

.comment-editor:has(.comment-editor-panel) {
  z-index: 100000;
}

.comment-header {
  display: flex;
  align-items: center;
}

.comment-toggle-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 10px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  background: rgba(40, 40, 80, 0.6);
  cursor: pointer;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  z-index: 1;
  min-height: 36px;
  font-size: 13px;
  font-weight: 500;
  color: #E8E8FF;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
  text-shadow: 0 0 3px rgba(255, 255, 255, 0.2);
}

.comment-toggle-btn:hover {
  background: rgba(60, 60, 120, 0.7);
  border-color: rgba(255, 255, 255, 0.3);
  transform: translateY(-1px);
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
}

.comment-toggle-btn:active {
  transform: translateY(0);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.2);
}

.comment-toggle-btn.has-comments {
  background: rgba(74, 144, 226, 0.8);
  border-color: rgba(74, 144, 226, 0.9);
  color: white;
  box-shadow: 0 0 10px rgba(74, 144, 226, 0.4);
}

.comment-toggle-btn.panel-open {
  z-index: auto !important;
  background: rgba(60, 60, 120, 0.5);
  border-color: rgba(255, 255, 255, 0.2);
}

.comment-icon {
  fill: currentColor;
  transition: fill 0.2s ease;
}

.comment-count {
  font-size: 11px;
  background: linear-gradient(135deg, #3182ce 0%, #2c5aa0 100%);
  color: white;
  border-radius: 10px;
  padding: 2px 6px;
  min-width: 16px;
  text-align: center;
  font-weight: 600;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
}

.comment-editor-panel {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  background: rgba(30, 30, 60, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 10px;
  box-shadow: 
    0 8px 20px rgba(0, 0, 0, 0.4),
    0 0 20px rgba(138, 43, 226, 0.15),
    inset 0 1px 0 rgba(255, 255, 255, 0.1);
  z-index: 999999;
  max-height: 400px;
  overflow-y: auto;
  width: 250px; /* 280px→250pxに縮小 */
  backdrop-filter: blur(15px);
  animation: slideIn 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.comment-panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 12px 16px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(40, 40, 80, 0.8);
  border-radius: 10px 10px 0 0;
}

.panel-title {
  font-size: 16px;
  font-weight: 700;
  color: #E8E8FF;
  text-shadow: 0 0 5px rgba(255, 255, 255, 0.3);
}

.close-panel-btn {
  background: none;
  border: none;
  padding: 6px;
  cursor: pointer;
  border-radius: 6px;
  transition: all 0.2s ease;
  color: #E8E8FF;
  min-height: 32px;
  min-width: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-panel-btn:hover {
  background: rgba(220, 53, 69, 0.8);
  color: white;
  transform: scale(1.05);
  box-shadow: 0 0 10px rgba(220, 53, 69, 0.4);
}

.comment-list {
  padding: 14px;
  max-height: 250px;
  overflow-y: auto;
  background: rgba(25, 25, 50, 0.3);
}

.comment-item {
  margin-bottom: 12px;
  padding: 10px;
  background: rgba(40, 40, 80, 0.4);
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  transition: all 0.2s ease;
}

.comment-item:hover {
  background: rgba(60, 60, 120, 0.5);
  border-color: rgba(255, 255, 255, 0.2);
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.comment-item:last-child {
  margin-bottom: 0;
}

.comment-content {
  white-space: pre-wrap;
  line-height: 1.5;
  margin-bottom: 8px;
  color: #E8E8FF;
  background-color: rgba(25, 25, 50, 0.6);
  padding: 10px;
  border-radius: 6px;
  border: 1px solid rgba(255, 255, 255, 0.05);
  min-height: 20px;
  font-size: 12px; /* 250px幅に合わせてさらに縮小 */
  font-weight: 400;
  box-shadow: inset 0 1px 3px rgba(0, 0, 0, 0.3);
  word-break: break-word;
  overflow-wrap: break-word;
  hyphens: auto;
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.1);
}

.comment-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 10px;
  color: rgba(232, 232, 255, 0.7);
  flex-wrap: wrap;
  gap: 6px;
}

.comment-date {
  font-size: 9px;
  color: rgba(232, 232, 255, 0.5);
}

.edit-btn, .delete-btn {
  padding: 3px 6px;
  font-size: 10px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 4px;
  background: rgba(40, 40, 80, 0.6);
  cursor: pointer;
  margin-left: 6px;
  transition: all 0.2s ease;
  font-weight: 500;
  min-height: 24px;
  color: #E8E8FF;
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.2);
}

.edit-btn:hover {
  background: rgba(74, 144, 226, 0.8);
  border-color: rgba(74, 144, 226, 0.9);
  color: white;
  transform: translateY(-1px);
  box-shadow: 0 0 8px rgba(74, 144, 226, 0.4);
}

.delete-btn:hover {
  background: rgba(220, 53, 69, 0.8);
  border-color: rgba(220, 53, 69, 0.9);
  color: white;
  transform: translateY(-1px);
  box-shadow: 0 0 8px rgba(220, 53, 69, 0.4);
}

.comment-textarea {
  width: 100%;
  min-height: 70px;
  padding: 10px;
  border: 2px solid rgba(255, 255, 255, 0.2);
  border-radius: 6px;
  resize: vertical;
  font-size: 12px;
  line-height: 1.5;
  font-family: system-ui, -apple-system, sans-serif;
  transition: border-color 0.2s ease, box-shadow 0.2s ease;
  background: rgba(25, 25, 50, 0.8);
  color: #E8E8FF;
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.1);
}

.comment-textarea:focus {
  outline: none;
  border-color: rgba(74, 144, 226, 0.8);
  box-shadow: 0 0 0 3px rgba(74, 144, 226, 0.2);
}

.comment-textarea::placeholder {
  color: rgba(232, 232, 255, 0.5);
}

.comment-edit-footer, .comment-new-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
  flex-wrap: wrap;
  gap: 6px;
}

.char-count {
  font-size: 10px;
  color: rgba(232, 232, 255, 0.7);
  font-weight: 500;
}

.edit-buttons, .new-buttons {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
}

.save-btn, .cancel-btn {
  padding: 5px 10px;
  font-size: 11px;
  border: 2px solid;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  font-weight: 600;
  min-height: 28px;
  min-width: 50px;
}

.save-btn {
  background: linear-gradient(135deg, #4A90E2 0%, #357ABD 100%);
  color: white;
  border-color: #4A90E2;
  box-shadow: 0 0 10px rgba(74, 144, 226, 0.3);
}

.save-btn:disabled {
  background: rgba(160, 174, 192, 0.5);
  border-color: rgba(160, 174, 192, 0.5);
  cursor: not-allowed;
  opacity: 0.6;
  box-shadow: none;
}

.cancel-btn {
  background: rgba(40, 40, 80, 0.8);
  color: #E8E8FF;
  border-color: rgba(255, 255, 255, 0.2);
}

.save-btn:hover:not(:disabled) {
  background: linear-gradient(135deg, #357ABD 0%, #2E6BA8 100%);
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.3), 0 0 15px rgba(74, 144, 226, 0.5);
}

.cancel-btn:hover {
  background: rgba(60, 60, 120, 0.8);
  border-color: rgba(255, 255, 255, 0.3);
  transform: translateY(-1px);
}

.comment-create {
  padding: 14px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(25, 25, 50, 0.3);
  border-radius: 0 0 10px 10px;
}

.add-comment-btn {
  width: 100%;
  padding: 10px;
  border: 2px dashed rgba(255, 255, 255, 0.3);
  border-radius: 6px;
  background: rgba(40, 40, 80, 0.6);
  cursor: pointer;
  color: #E8E8FF;
  font-size: 11px;
  font-weight: 500;
  transition: all 0.2s ease;
  min-height: 32px;
  text-shadow: 0 0 2px rgba(255, 255, 255, 0.2);
}

.add-comment-btn:hover {
  background: rgba(60, 60, 120, 0.7);
  border-color: rgba(255, 255, 255, 0.4);
  color: white;
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.3);
}

.comment-new {
  padding: 14px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(25, 25, 50, 0.3);
}

.loading {
  padding: 18px;
  text-align: center;
  color: rgba(232, 232, 255, 0.7);
  font-size: 12px;
  font-weight: 500;
}

.success-message {
  padding: 10px 14px;
  text-align: center;
  color: #48bb78;
  font-size: 12px;
  font-weight: 600;
  background: rgba(72, 187, 120, 0.1);
  border: 1px solid rgba(72, 187, 120, 0.3);
  border-radius: 6px;
  margin: 10px 14px;
  animation: fadeIn 0.3s ease;
  box-shadow: 0 0 10px rgba(72, 187, 120, 0.2);
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

/* レスポンシブデザイン */
@media (max-width: 768px) {
  .comment-editor-panel {
    position: fixed;
    top: 60px;
    left: 50%;
    right: auto;
    transform: translateX(-50%);
    width: calc(100vw - 20px);
    max-width: 400px;
    max-height: calc(100vh - 80px);
    border-radius: 12px;
    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);
    z-index: 1000000;
  }
  
  .comment-toggle-btn {
    padding: 8px 12px;
    font-size: 14px;
    min-height: 44px;
  }
  
  .comment-list {
    padding: 16px;
    max-height: calc(100vh - 200px);
  }
  
  .comment-item {
    padding: 14px;
    margin-bottom: 12px;
  }
  
  .comment-content {
    padding: 12px;
    font-size: 14px;
  }
  
  .comment-textarea {
    min-height: 100px;
    padding: 14px;
    font-size: 14px;
  }
  
  .panel-title {
    font-size: 18px;
  }
  
  .comment-panel-header {
    padding: 16px 20px;
  }
  
  .comment-create, .comment-new {
    padding: 20px;
  }
  
  .edit-buttons, .new-buttons {
    width: 100%;
    justify-content: stretch;
  }
  
  .save-btn, .cancel-btn {
    flex: 1;
    min-width: unset;
    padding: 12px 16px;
    min-height: 44px;
  }
  
  .comment-meta {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .edit-btn, .delete-btn {
    margin-left: 0;
    margin-top: 6px;
    min-height: 36px;
    padding: 8px 12px;
  }
  
  .add-comment-btn {
    padding: 16px;
    font-size: 14px;
    min-height: 44px;
  }
}

@media (max-width: 480px) {
  .comment-editor-panel {
    top: 40px;
    left: 10px;
    right: 10px;
    transform: none;
    width: calc(100vw - 20px);
    max-height: calc(100vh - 60px);
  }
  
  .comment-toggle-btn {
    padding: 6px 10px;
    font-size: 13px;
    min-height: 40px;
  }
  
  .comment-count {
    font-size: 10px;
    padding: 2px 5px;
  }
  
  .panel-title {
    font-size: 16px;
  }
  
  .comment-panel-header {
    padding: 12px 16px;
  }
  
  .comment-create, .comment-new {
    padding: 16px;
  }
}

@media (max-width: 320px) {
  .comment-editor-panel {
    left: 5px;
    right: 5px;
    width: calc(100vw - 10px);
  }
  
  .comment-toggle-btn {
    padding: 4px 8px;
    gap: 4px;
    font-size: 12px;
    min-height: 36px;
  }
  
  .comment-content {
    font-size: 12px;
    padding: 8px;
  }
  
  .comment-textarea {
    font-size: 12px;
    padding: 10px;
  }
}

/* デスクトップでの幅制限維持 */
@media (min-width: 769px) {
  .comment-editor-panel {
    width: 250px; /* 280px→250pxに変更 */
    max-width: 250px;
  }
}

/* スマホでのオーバーレイ背景 */
@media (max-width: 768px) {
  .comment-editor:has(.comment-editor-panel)::before {
    content: '';
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0, 0, 0, 0.6);
    z-index: 999998;
    animation: fadeIn 0.3s ease;
  }
}

/* アクセシビリティ */
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

/* フォーカス表示の改善 */
.comment-toggle-btn:focus-visible,
.close-panel-btn:focus-visible,
.edit-btn:focus-visible,
.delete-btn:focus-visible,
.save-btn:focus-visible,
.cancel-btn:focus-visible,
.add-comment-btn:focus-visible {
  outline: 2px solid #4A90E2;
  outline-offset: 2px;
}

/* スクロールバーのスタイル調整 */
.comment-list::-webkit-scrollbar {
  width: 4px;
}

.comment-list::-webkit-scrollbar-track {
  background: rgba(40, 40, 80, 0.3);
  border-radius: 2px;
}

.comment-list::-webkit-scrollbar-thumb {
  background: rgba(74, 144, 226, 0.6);
  border-radius: 2px;
}

.comment-list::-webkit-scrollbar-thumb:hover {
  background: rgba(74, 144, 226, 0.8);
}
</style> 