import { defineStore } from 'pinia';
import { Api } from '@/services/api/api';
import { parseSFEN } from '@/utils/sfenParser';
import  *  as Types from '@/store/types';

const api = new Api({
    baseUrl: 'http://localhost:3000'
});

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
        game: null,
        selectedCell: {x: null, y: null},
        validMovesCache: null as Types.ValidMovesCache | null,
    }),
    actions: {
        async handleAsyncAction(asyncAction: () => Promise<void>, errorMessage: string = 'エラーが発生しました') {
            this.isError = false;
            try {
                await asyncAction();
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

                this.is_checkmate = false;
                this.is_repetition = false;
                this.is_repetition_check = false;

                await this.fetchBoard();
            }, 'ゲームの作成に失敗しました');
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

                const response = await api.api.v1GamesBoardsMovePartialUpdate(
                    game_id,
                    board_id,
                    { move: usiMove }
                );

                await this._updateGameStateFromResponse(response);
            }, '駒を打つことができませんでした');
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

        updateGameState(gameData: Pick<Types.Game, 'id' | 'status' | 'board_id'>) {
            this.game = gameData;
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
            const response = await api.api.v1GamesBoardsMovePartialUpdate(
                game_id,
                board_id,
                { move: usiMove }
            );

            if (!response.data.sfen) {
                throw new Error('SFEN data is missing');
            }

            return response;
        },

        async _updateGameStateFromResponse(response: any) {
            const parsed = parseSFEN(response.data.sfen);
            this.shogiData.board = parsed.board;
            this.shogiData.piecesInHand = parsed.piecesInHand;
            this.activePlayer = parsed.playerToMove;
            this.stepNumber = parsed.moveCount;

            this.board_id = response.data.board_id ?? null;
            this.is_checkmate = response.data.is_checkmate;
            this.is_repetition = response.data.is_repetition;
            this.is_repetition_check = response.data.is_repetition_check;
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
    }
});

const initializeShogiData = (): Types.ShogiData => ({
    board: Array.from({ length: 9 }, () => Array(9).fill(null)) as (Types.ShogiPiece | null)[][],
    piecesInHand: {},
    sfen: ''
});
