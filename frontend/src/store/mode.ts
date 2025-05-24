import { defineStore } from 'pinia';
import { GameMode } from '@/store/types';
import { Api } from '@/services/api/api';
import { useBoardStore } from '@/store';

// APIクライアントの作成
const api = new Api({
    baseUrl: 'http://localhost:3000'
});

export interface ModeState {
    currentMode: GameMode;
    isLoading: boolean;
    error: string | null;
}

export const useModeStore = defineStore('mode', {
    state: (): ModeState => ({
        currentMode: GameMode.EDIT,
        isLoading: false,
        error: null
    }),

    actions: {
        /**
         * ゲームモードを変更する
         * @param gameId ゲームID
         * @param newMode 新しいモード
         * @returns APIレスポンス
         */
        async changeMode(gameId: number, newMode: GameMode) {
            const boardStore = useBoardStore();
            
            if (!gameId) {
                this.error = 'ゲームIDが指定されていません';
                return;
            }

            this.isLoading = true;
            this.error = null;

            try {
                // APIクライアントを使用してモード変更リクエスト送信
                const response = await api.api.v1GamesModeCreate(gameId, { mode: newMode });
                
                // モードの更新
                this.currentMode = newMode;
                
                // ゲーム情報の更新
                if (boardStore.game) {
                    boardStore.game.mode = newMode;
                }
                
                // 必要に応じて盤面情報を再取得
                await boardStore.fetchBoard();
                
                return response.data;
            } catch (error) {
                console.error('モード変更中にエラーが発生しました:', error);
                this.error = 'モードの変更に失敗しました';
                throw error;
            } finally {
                this.isLoading = false;
            }
        },

        /**
         * 現在のモードを初期化（ゲーム情報から取得）
         * @param gameMode 初期モード（省略可）
         */
        initializeMode(gameMode?: GameMode) {
            if (gameMode) {
                this.currentMode = gameMode;
            } else {
                const boardStore = useBoardStore();
                if (boardStore.game?.mode) {
                    this.currentMode = boardStore.game.mode;
                } else {
                    this.currentMode = GameMode.PLAY; // デフォルト値
                }
            }
        },

        /**
         * URLパラメータからモードを初期化
         */
        initializeModeFromUrl() {
            const urlParams = new URLSearchParams(window.location.search);
            const modeParam = urlParams.get('mode');
            
            if (modeParam) {
                console.log('🎯 URLからモード設定:', modeParam);
                switch (modeParam.toLowerCase()) {
                    case 'study':
                        this.currentMode = GameMode.STUDY;
                        break;
                    case 'edit':
                        this.currentMode = GameMode.EDIT;
                        break;
                    case 'play':
                        this.currentMode = GameMode.PLAY;
                        break;
                    default:
                        console.warn('未知のモード:', modeParam);
                        this.currentMode = GameMode.PLAY;
                }
            } else {
                this.currentMode = GameMode.PLAY; // デフォルト値
            }
        },
        
        /**
         * エラーをクリア
         */
        clearError() {
            this.error = null;
        }
    }
}); 