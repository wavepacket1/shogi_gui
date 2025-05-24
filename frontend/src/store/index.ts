import { defineStore } from 'pinia';
import { Api } from '@/services/api/api';
import { parseSFEN } from '@/utils/sfenParser';
import  *  as Types from '@/store/types';
import { createPinia } from 'pinia';
import { NonNullPieceType } from '@/types/shogi';

const api = new Api({
    baseUrl: 'http://localhost:3000'
});

const pinia = createPinia();

// Shogiゲームデータの初期化
export const initialShogiData = {
  board: Array(9).fill(null).map(() => Array(9).fill(null)),
  currentSide: 'b' as const,
  gameId: null,
  unsavedChanges: false,
  piecesInHand: {} as Record<NonNullPieceType, number>
};

export const useBoardStore = defineStore('board', {
    state: (): Types.BoardState => ({
        shogiData: initializeShogiData(),
        stepNumber: 0,
        activePlayer: null,
        board_id: null,
        isError: false,
        is_checkmate: false,
        is_repetition: false,
        is_repetition_check: false,
        is_check_entering_king: null,
        game: null,
        selectedCell: {x: null, y: null},
        validMovesCache: null as Types.ValidMovesCache | null,
        boardHistories: [],
        currentBranch: 'main',
        branches: ['main'],
        currentMoveIndex: -1
    }),
    actions: {
        async handleAsyncAction<T>(asyncAction: () => Promise<T>, errorMessage: string = 'エラーが発生しました'): Promise<T | void> {
            this.isError = false;
            try {
                return await asyncAction();
            } catch (error: unknown) {
                if(error instanceof Error) {
                    console.error(errorMessage, error.message);
                } else {
                    console.error(errorMessage, error);
                }
                this.isError = true;
            }
        },

        async movePiece(game_id: number, board_id: number, X: number, Y: number, promote: boolean = false) {
            await this.handleAsyncAction(async () => {
                this._validatePieceSelection();
                const usiMove = this._createUSIMove(X, Y, promote);
                const response = await this._executeMove(game_id, board_id, usiMove);
                await this._updateGameStateFromResponse(response);
                this.SetCell(null);
                this.clearValidMovesCache();
            }, '駒の移動に失敗しました');
        },

        async createGame() {
            await this.handleAsyncAction(async () => {
                const response = await api.api.v1GamesCreate({ status: 'active' });

                const data = response.data as Types.GameResponse;
                
                if (!data.game_id || !data.status || !data.board_id) {
                    throw new Error('Invalid game data: Missing required fields');
                }

                this.updateGameState({
                    id: data.game_id,
                    status: data.status,
                    board_id: data.board_id
                });

                this.resetGameFlag();

                await this.fetchBoard();
            }, 'ゲームの作成に失敗しました');
        },

        // 既存ゲームの読み込み
        async loadExistingGame(gameId: number) {
            await this.handleAsyncAction(async () => {
                // ゲーム詳細を取得
                const gameResponse = await fetch(`http://localhost:3000/api/v1/games/${gameId}`);
                if (!gameResponse.ok) {
                    throw new Error(`ゲーム ${gameId} が見つかりません`);
                }
                
                const gameData = await gameResponse.json();
                
                this.updateGameState({
                    id: gameData.id,
                    status: gameData.status,
                    mode: gameData.mode,
                    board_id: gameData.board?.id
                });

                // 盤面情報を取得
                if (gameData.board?.id) {
                    await this.fetchBoard();
                }

                // 棋譜履歴を取得
                await this.fetchBoardHistories(gameId, this.currentBranch, false);
                
                console.log('✅ 既存ゲーム読み込み完了:', gameId);
            }, `既存ゲーム ${gameId} の読み込みに失敗しました`);
        },

        // URLパラメータまたは既存ゲームの初期化
        async initializeGameFromUrl() {
            await this.handleAsyncAction(async () => {
                // URLパラメータからゲームIDを取得
                const urlParams = new URLSearchParams(window.location.search);
                const gameIdFromUrl = urlParams.get('game_id') || urlParams.get('gameId');
                
                if (gameIdFromUrl) {
                    const gameId = parseInt(gameIdFromUrl);
                    if (!isNaN(gameId)) {
                        console.log('🎮 URLからゲームID指定:', gameId);
                        await this.loadExistingGame(gameId);
                        return;
                    }
                }
                
                // ローカルストレージからゲームIDを取得
                const storedGameId = localStorage.getItem('currentGameId');
                if (storedGameId) {
                    const gameId = parseInt(storedGameId);
                    if (!isNaN(gameId)) {
                        console.log('💾 ローカルストレージからゲームID取得:', gameId);
                        try {
                            await this.loadExistingGame(gameId);
                            return;
                        } catch (error) {
                            console.warn('ローカルストレージのゲームが無効、新規作成します:', error);
                            localStorage.removeItem('currentGameId');
                        }
                    }
                }
                
                // 既存ゲームがない場合は新規作成
                console.log('🆕 新しいゲームを作成します');
                await this.createGame();
                
                // 作成したゲームIDをローカルストレージに保存
                if (this.game?.id) {
                    localStorage.setItem('currentGameId', this.game.id.toString());
                }
            }, 'ゲームの初期化に失敗しました');
        },


        async enteringKingDeclaration(game_id: number, board_id: number) {
            await this.handleAsyncAction(async () => {
                const response = await api.api.v1GamesBoardsNyugyokuDeclarationCreate(
                    game_id,
                    board_id
                );

                if (response.data.status === 'success') {
                    this.is_check_entering_king = true;
                }
                else {
                    this.is_check_entering_king = false;
                }
            }, '入玉宣言のAPIの取得に失敗しました');
        },

        async fetchBoard() {
            await this.handleAsyncAction(async () => {
                const response = await api.api.v1BoardsDefaultList();
                const parsed = parseSFEN(response.data.sfen);

                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
                this.activePlayer = parsed.playerToMove;
                this.stepNumber = parsed.moveCount;
            }, 'ボードの取得に失敗しました');
        },

        async dropPiece(game_id: number, board_id: number, piece: string, x: number, y: number) {
            await this.handleAsyncAction(async () => {
                const pos = this._convertPosition(x, y);
                const usiMove = `${piece}*${pos.x}${pos.y}`;

                // 現在の手数を取得
                const currentMoveNumber = this.currentMoveIndex >= 0 ? 
                    this.boardHistories[this.currentMoveIndex]?.move_number || 0 : 0;

                            const response = await api.api.v1GamesBoardsMovePartialUpdate(
                game_id,
                board_id,
                { 
                    move: usiMove
                },
                {
                    move_number: currentMoveNumber,
                    branch: this.currentBranch
                }
            );

                await this._updateGameStateFromResponse(response);
            }, '駒を打つことができませんでした');
        },

        resetGameFlag() {
            this.is_checkmate = false;
            this.is_repetition = false;
            this.is_repetition_check = false;
            this.is_check_entering_king = null;
        },

        SetCell(clickedCell: {x: number, y: number} | null) {
            if (clickedCell) {
                this.selectedCell.x = clickedCell.x;
                this.selectedCell.y = clickedCell.y;
            } else {
                this.selectedCell.x = null;
                this.selectedCell.y = null;
            }
        },

        updateGameState(gameData: Pick<Types.Game, 'id' | 'status' | 'board_id' | 'mode'>) {
            this.game = {
                id: gameData.id,
                status: gameData.status,
                board_id: gameData.board_id,
                mode: gameData.mode
            };
            this.board_id = gameData.board_id;
        },

        clearValidMovesCache() {
            this.validMovesCache = null;
        },

        updateValidMovesCache() {
            this.validMovesCache = {
                board_state: this.shogiData.sfen,
                moves: {}
            };
        },

         // ヘルパーメソッド
        async _executeMove(game_id: number, board_id: number, usiMove: string) {
            // 現在の手数を取得
            const currentMoveNumber = this.currentMoveIndex >= 0 ? 
                this.boardHistories[this.currentMoveIndex]?.move_number || 0 : 0;
            
            console.log('🎮 フロント指し手送信:', {
                game_id,
                board_id,
                move: usiMove,
                move_number: currentMoveNumber,
                branch: this.currentBranch,
                currentMoveIndex: this.currentMoveIndex,
                historiesLength: this.boardHistories.length
            });
            
            const response = await api.api.v1GamesBoardsMovePartialUpdate(
                game_id,
                board_id,
                { 
                    move: usiMove
                },
                {
                    move_number: currentMoveNumber,
                    branch: this.currentBranch
                }
            );

            console.log('📨 API応答:', response.data);
            console.log('📨 完全なレスポンス:', JSON.stringify(response, null, 2));

            if (!response.data.sfen) {
                throw new Error('SFEN data is missing');
            }

            return response;
        },

        async _updateGameStateFromResponse(response: any, skipHistoryUpdate: boolean = false) {
            const parsed = parseSFEN(response.data.sfen);
            this.shogiData.board = parsed.board;
            this.shogiData.piecesInHand = parsed.piecesInHand;
            this.activePlayer = parsed.playerToMove;

            this.board_id = response.data.board_id ?? null;
            this.is_checkmate = response.data.is_checkmate;
            this.is_repetition = response.data.is_repetition;
            this.is_repetition_check = response.data.is_repetition_check;
            
            // 駒を動かした後に履歴を更新（一度だけ）
            if (!skipHistoryUpdate && this.game?.id) {
                try {
                    console.log('🔄 履歴更新開始:', {
                        gameId: this.game.id,
                        currentBranch: this.currentBranch,
                        currentHistoriesLength: this.boardHistories.length
                    });
                    // 履歴を一度だけ更新
                    await this.fetchBoardHistories(this.game.id, this.currentBranch, false);
                    console.log('✅ 履歴更新完了:', {
                        newHistoriesLength: this.boardHistories.length,
                        currentMoveIndex: this.currentMoveIndex
                    });
                } catch (error) {
                    console.error('履歴の更新に失敗しました:', error);
                }
            }

            this.stepNumber = parsed.moveCount;
        },

        _validatePieceSelection() {
            if (this.selectedCell.x === null || this.selectedCell.y === null) {
                throw new Error('No piece selected');
            }
        },

        _convertPosition(x: number, y: number) {
            return {
                x: 9 - x,
                y: String.fromCharCode(97 + y)
            };
        },

        _createUSIMove(toX: number, toY: number, promote: boolean): string {
            const from = this._convertPosition(this.selectedCell.x!, this.selectedCell.y!);
            const to = this._convertPosition(toX, toY);
            return `${from.x}${from.y}${to.x}${to.y}${promote ? '+' : ''}`;
        },

        async fetchBoardHistories(gameId: number, branch?: string, preserveCurrentIndex: boolean = false) {
            if (!gameId) {
                console.error('Game ID is required');
                return { data: [] };
            }

            return await this.handleAsyncAction(async () => {
                const targetBranch = branch || this.currentBranch;
                const response = await api.api.v1GamesBoardHistoriesList(gameId, { branch: targetBranch });
                
                // 履歴を更新
                this.boardHistories = response.data as unknown as Types.BoardHistory[];
                
                // preserveCurrentIndexがfalseの場合のみ最新の手にハイライトを移動
                if (!preserveCurrentIndex) {
                    this.currentMoveIndex = this.boardHistories.length - 1;
                }
                
                return response;
            }, '盤面履歴の取得に失敗しました');
        },

        async fetchBranches(gameId: number) {
            if (!gameId) {
                console.error('Game ID is required');
                return { data: { branches: ['main'] } };
            }

            return await this.handleAsyncAction(async () => {
                const response = await api.api.v1GamesBoardHistoriesBranchesList(gameId);
                this.branches = (response.data as unknown as Types.BranchesResponse).branches;
                return response;
            }, '分岐一覧の取得に失敗しました');
        },

        async navigateToMove(params: { gameId: number, moveNumber: number }) {
            const { gameId, moveNumber } = params;
            if (!gameId || moveNumber === undefined) {
                console.error('Game ID and move number are required');
                return;
            }

            return await this.handleAsyncAction(async () => {
                // 履歴配列の中から対応する手数のオブジェクトを探す
                const historyItem = this.boardHistories.find(h => h.move_number === moveNumber);
                if (!historyItem) {
                    console.error(`Move number ${moveNumber} not found in history`);
                    return;
                }
                
                // APIを呼び出して局面に移動
                const response = await api.api.v1GamesNavigateToCreate(
                    gameId,
                    moveNumber,
                    { branch: this.currentBranch }
                );
                
                // 盤面情報を更新（履歴の更新はスキップ）
                await this._updateGameStateFromResponse(response, true);
                
                // 選択した手数のインデックスを設定
                const targetIndex = this.boardHistories.findIndex(h => h.move_number === moveNumber);
                if (targetIndex !== -1) {
                    this.currentMoveIndex = targetIndex;
                }
                
                return response;
            }, '特定の手数への移動に失敗しました');
        },

        async switchBranch(params: { gameId: number, branchName: string }) {
            const { gameId, branchName } = params;
            if (!gameId || !branchName) {
                console.error('Game ID and branch name are required');
                return;
            }

            return await this.handleAsyncAction(async () => {
                const response = await api.api.v1GamesSwitchBranchCreate(gameId, branchName);
                const responseData = response.data as unknown as { 
                    sfen: string; 
                    board_id: number;
                    game_id: number;
                    branch: string;
                };

                const parsed = parseSFEN(responseData.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
                this.activePlayer = parsed.playerToMove;
                this.stepNumber = parsed.moveCount;
                this.board_id = responseData.board_id;
                
                this.currentBranch = branchName;
                await this.fetchBoardHistories(gameId, branchName);
                
                return response;
            }, '分岐切り替えに失敗しました');
        },

        // 投了アクション
        async resignGame(gameId: number) {
            return await this.handleAsyncAction(async () => {
                const response = await api.api.v1GamesIdResignCreate(gameId);
                
                if (response.data.status === 'success') {
                    // ゲームの状態を更新
                    if (this.game) {
                        this.game.status = response.data.game_status;
                    }
                }
                
                return response;
            }, '投了処理に失敗しました');
        }
    }
});

const initializeShogiData = (): Types.ShogiData => ({
    board: Array.from({ length: 9 }, () => Array(9).fill(null)) as (Types.ShogiPiece | null)[][],
    piecesInHand: {},
    sfen: ''
});

export default pinia;
