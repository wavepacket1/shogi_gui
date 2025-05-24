import { defineStore } from 'pinia'
import type { Comment, StudyState } from '@/types/shogi'

export const useStudyModeStore = defineStore('studyMode', {
  state: (): StudyState => ({
    comments: {},
    editingCommentId: null,
    autoSaveTimer: null,
    currentGameId: null,
    currentMoveNumber: null,
    currentBranch: 'main',
    isLoadingComments: false,
  }),

  getters: {
    getCommentsForMove: (state) => {
      return (boardHistoryId: string | number): Comment[] => {
        // 数値キーと文字列キーの両方を確認
        const numKey = typeof boardHistoryId === 'string' ? parseInt(boardHistoryId) : boardHistoryId
        const strKey = String(boardHistoryId)
        
        // 重複を避けるため、まず元のキーで検索、なければ数値キー、最後に文字列キー
        const comments = state.comments[boardHistoryId] || state.comments[numKey] || state.comments[strKey] || []
        
        // さらに安全のため、IDの重複を除去
        const uniqueComments = comments.filter((comment, index, arr) => 
          arr.findIndex(c => c.id === comment.id) === index
        )
        
        return uniqueComments
      }
    },

    hasComments: (state) => {
      return (boardHistoryId: string | number): boolean => {
        // 数値キーと文字列キーの両方を確認
        const numKey = typeof boardHistoryId === 'string' ? parseInt(boardHistoryId) : boardHistoryId
        const strKey = String(boardHistoryId)
        const comments = state.comments[boardHistoryId] || state.comments[numKey] || state.comments[strKey]
        return comments && comments.length > 0
      }
    },

    isEditing: (state) => {
      return (commentId: number): boolean => {
        return state.editingCommentId === commentId
      }
    }
  },

  actions: {
    // 基本設定
    setCurrentGame(gameId: number, moveNumber: number | null = null, branch: string = 'main') {
      this.currentGameId = gameId
      this.currentMoveNumber = moveNumber
      this.currentBranch = branch
    },

    // コメント一覧の取得
    async fetchComments(gameId: number, moveNumber: number, branch: string = 'main'): Promise<void> {
      this.isLoadingComments = true
      
      try {
        const url = `/api/v1/games/${gameId}/moves/${moveNumber}/comments?branch=${encodeURIComponent(branch)}`
        const response = await fetch(url)
        
        if (!response.ok) {
          if (response.status === 404) {
            // board_historyが存在しない場合は空配列を格納
            const tempBoardHistoryId = `${gameId}-${moveNumber}-${branch}`
            this.comments[tempBoardHistoryId] = []
            return
          }
          throw new Error(`コメント取得に失敗しました: ${response.status}`)
        }

        const comments: Comment[] = await response.json()
        
        // board_history_idをキーとしてコメントを格納
        // board_historyが存在しない場合は一意なキーを生成
        let boardHistoryId: string | number
        if (comments.length > 0) {
          boardHistoryId = comments[0].board_history_id
        } else {
          boardHistoryId = `${gameId}-${moveNumber}-${branch}`
        }
        
        // 数値キーと文字列キーの両方で格納
        const numKey = typeof boardHistoryId === 'string' ? parseInt(boardHistoryId) : boardHistoryId
        const strKey = String(boardHistoryId)
        
        this.comments[numKey] = comments
        this.comments[strKey] = comments
      } catch (error) {
        console.error('コメント取得エラー:', error)
        throw error
      } finally {
        this.isLoadingComments = false
      }
    },

    // コメントの作成
    async createComment(gameId: number, moveNumber: number, content: string): Promise<Comment> {
      try {
        const response = await fetch(`/api/v1/games/${gameId}/moves/${moveNumber}/comments`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ comment: { content } }),
        })

        if (!response.ok) {
          const errorData = await response.text()
          console.error('API Error Response:', errorData)
          throw new Error(`コメント作成に失敗しました: ${response.status}`)
        }

        const responseData = await response.json()
        
        // バックエンドのレスポンス形式に対応
        const newComment: Comment = {
          id: responseData.comment_id || responseData.id,
          board_history_id: responseData.board_history_id,
          content: responseData.content,
          created_at: responseData.created_at || responseData.updated_at,
          updated_at: responseData.updated_at
        }
        
        // コメント作成後は重複を避けるため、直接追加せずにfetchCommentsで最新データを取得
        // これにより、サーバーから最新の状態を取得し、重複問題を回避
        await this.fetchComments(gameId, moveNumber)

        return newComment
      } catch (error) {
        console.error('コメント作成エラー:', error)
        throw error
      }
    },

    // コメントの更新
    async updateComment(gameId: number, moveNumber: number, commentId: number, content: string): Promise<Comment> {
      try {
        const response = await fetch(`/api/v1/games/${gameId}/moves/${moveNumber}/comments/${commentId}`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ comment: { content } }),
        })

        if (!response.ok) {
          const errorData = await response.text()
          console.error('API Error Response:', errorData)
          throw new Error(`コメント更新に失敗しました: ${response.status}`)
        }

        const responseData = await response.json()
        
        // バックエンドのレスポンス形式に対応
        const updatedComment: Comment = {
          id: responseData.comment_id || responseData.id || commentId,
          board_history_id: responseData.board_history_id,
          content: responseData.content,
          created_at: responseData.created_at || responseData.updated_at,
          updated_at: responseData.updated_at
        }
        
        // ローカルステートを更新
        const boardHistoryId = updatedComment.board_history_id
        const numKey = typeof boardHistoryId === 'string' ? parseInt(boardHistoryId) : boardHistoryId
        const strKey = String(boardHistoryId)
        
        // 数値キーで更新
        if (this.comments[numKey]) {
          const index = this.comments[numKey].findIndex(c => c.id === commentId)
          if (index !== -1) {
            this.comments[numKey][index] = updatedComment
          }
        }
        
        // 文字列キーでも更新
        if (this.comments[strKey]) {
          const index = this.comments[strKey].findIndex(c => c.id === commentId)
          if (index !== -1) {
            this.comments[strKey][index] = updatedComment
          }
        }

        return updatedComment
      } catch (error) {
        console.error('コメント更新エラー:', error)
        throw error
      }
    },

    // コメントの削除
    async deleteComment(gameId: number, moveNumber: number, commentId: number): Promise<void> {
      try {
        const response = await fetch(`/api/v1/games/${gameId}/moves/${moveNumber}/comments/${commentId}`, {
          method: 'DELETE',
        })

        if (!response.ok) {
          throw new Error(`コメント削除に失敗しました: ${response.status}`)
        }

        // ローカルステートから削除
        Object.keys(this.comments).forEach(key => {
          if (this.comments[key]) {
            this.comments[key] = this.comments[key].filter(c => c.id !== commentId)
            
            // 空配列になった場合は削除
            if (this.comments[key].length === 0) {
              delete this.comments[key]
            }
          }
        })
      } catch (error) {
        console.error('コメント削除エラー:', error)
        throw error
      }
    },

    // 編集状態の管理
    startEditing(commentId: number) {
      this.editingCommentId = commentId
    },

    stopEditing() {
      this.editingCommentId = null
      // 自動保存タイマーもクリア
      if (this.autoSaveTimer) {
        clearTimeout(this.autoSaveTimer)
        this.autoSaveTimer = null
      }
    },

    // 自動保存機能
    scheduleAutoSave(gameId: number, moveNumber: number, commentId: number, content: string) {
      // 既存のタイマーをクリア
      if (this.autoSaveTimer) {
        clearTimeout(this.autoSaveTimer)
      }

      // 3秒後に自動保存
      this.autoSaveTimer = setTimeout(async () => {
        try {
          await this.updateComment(gameId, moveNumber, commentId, content)
          console.log('コメントが自動保存されました')
        } catch (error) {
          console.error('自動保存に失敗しました:', error)
        }
        this.autoSaveTimer = null
      }, 3000)
    },

    // ストアのリセット
    reset() {
      this.comments = {}
      this.editingCommentId = null
      this.currentGameId = null
      this.currentMoveNumber = null
      this.currentBranch = 'main'
      this.isLoadingComments = false
      
      if (this.autoSaveTimer) {
        clearTimeout(this.autoSaveTimer)
        this.autoSaveTimer = null
      }
    }
  }
}) 