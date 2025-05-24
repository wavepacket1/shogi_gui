<template>
  <div class="comment-editor">
    <div class="comment-header">
      <button 
        class="comment-toggle-btn"
        @click="toggleEditor"
        :class="{ 'has-comments': hasComments }"
      >
        <svg class="comment-icon" viewBox="0 0 24 24" width="16" height="16">
          <path d="M20 2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h14l4 4V4c0-1.1-.9-2-2-2z"/>
        </svg>
        <span class="comment-count" v-if="comments.length > 0">{{ comments.length }}</span>
      </button>
    </div>

    <div v-if="isEditorOpen" class="comment-editor-panel">
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
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
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

// 参照
const editTextarea = ref<HTMLTextAreaElement>()
const newTextarea = ref<HTMLTextAreaElement>()

// 計算プロパティ
const comments = computed(() => studyStore.getCommentsForMove(props.boardHistoryId))
const hasComments = computed(() => studyStore.hasComments(props.boardHistoryId))

// エディター表示切り替え
const toggleEditor = async () => {
  isEditorOpen.value = !isEditorOpen.value
  
  if (isEditorOpen.value && comments.value.length === 0) {
    // コメントがロードされていない場合は取得
    try {
      await studyStore.fetchComments(props.gameId, props.moveNumber)
    } catch (error) {
      console.error('コメント取得に失敗しました:', error)
    }
  }
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
  if (!confirm('このコメントを削除しますか？')) return
  
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

// マウント時の設定
onMounted(() => {
  studyStore.setCurrentGame(props.gameId, props.moveNumber)
})
</script>

<style scoped>
.comment-editor {
  position: relative;
}

.comment-header {
  display: flex;
  align-items: center;
}

.comment-toggle-btn {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 4px 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  background: #f9f9f9;
  cursor: pointer;
  transition: all 0.2s;
}

.comment-toggle-btn:hover {
  background: #e9e9e9;
}

.comment-toggle-btn.has-comments {
  background: #e3f2fd;
  border-color: #2196f3;
}

.comment-icon {
  fill: #666;
}

.comment-toggle-btn.has-comments .comment-icon {
  fill: #2196f3;
}

.comment-count {
  font-size: 12px;
  background: #2196f3;
  color: white;
  border-radius: 10px;
  padding: 2px 6px;
  min-width: 16px;
  text-align: center;
}

.comment-editor-panel {
  position: absolute;
  top: 100%;
  left: 0;
  right: 0;
  background: white;
  border: 1px solid #ddd;
  border-radius: 4px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  z-index: 1000;
  max-height: 400px;
  overflow-y: auto;
}

.comment-list {
  padding: 8px;
}

.comment-item {
  margin-bottom: 12px;
  padding-bottom: 12px;
  border-bottom: 1px solid #eee;
}

.comment-item:last-child {
  border-bottom: none;
  margin-bottom: 0;
}

.comment-content {
  white-space: pre-wrap;
  line-height: 1.5;
  margin-bottom: 8px;
}

.comment-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 12px;
  color: #666;
}

.comment-date {
  font-size: 11px;
}

.edit-btn, .delete-btn {
  padding: 2px 6px;
  font-size: 11px;
  border: 1px solid #ddd;
  border-radius: 2px;
  background: white;
  cursor: pointer;
  margin-left: 4px;
}

.edit-btn:hover {
  background: #e3f2fd;
}

.delete-btn:hover {
  background: #ffebee;
}

.comment-textarea {
  width: 100%;
  min-height: 80px;
  padding: 8px;
  border: 1px solid #ddd;
  border-radius: 4px;
  resize: vertical;
  font-size: 14px;
  line-height: 1.5;
}

.comment-edit-footer, .comment-new-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: 8px;
}

.char-count {
  font-size: 12px;
  color: #666;
}

.edit-buttons, .new-buttons {
  display: flex;
  gap: 8px;
}

.save-btn, .cancel-btn {
  padding: 4px 12px;
  font-size: 12px;
  border: 1px solid #ddd;
  border-radius: 4px;
  cursor: pointer;
}

.save-btn {
  background: #2196f3;
  color: white;
  border-color: #2196f3;
}

.save-btn:disabled {
  background: #ccc;
  border-color: #ccc;
  cursor: not-allowed;
}

.cancel-btn {
  background: white;
}

.save-btn:hover:not(:disabled) {
  background: #1976d2;
}

.cancel-btn:hover {
  background: #f5f5f5;
}

.comment-create {
  padding: 8px;
  border-top: 1px solid #eee;
}

.add-comment-btn {
  width: 100%;
  padding: 8px;
  border: 1px dashed #ddd;
  border-radius: 4px;
  background: #fafafa;
  cursor: pointer;
  color: #666;
}

.add-comment-btn:hover {
  background: #f0f0f0;
  border-color: #bbb;
}

.comment-new {
  padding: 8px;
  border-top: 1px solid #eee;
}

.loading {
  padding: 16px;
  text-align: center;
  color: #666;
  font-size: 14px;
}
</style> 