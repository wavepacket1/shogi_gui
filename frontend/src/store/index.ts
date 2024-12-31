import { defineStore } from 'pinia';
import { Api } from '@/services/api/api';
import { parseSFEN } from '@/utils/sfenParser';

const api = new Api({
  baseUrl: 'http://localhost:3000'
});

export interface Game {
    id: number;
    name?: string;
    status: string;
    board_id: number;
}

export interface ShogiData {
    board: (ShogiPiece | null)[][];
    piecesInHand: Record<string, number>;
    sfen: string;
}

export interface BoardState {
    shogiData: ShogiData;
    step_number: number;
    active_player: 'b' | 'w' | null;
    board_id: number | null;
    isError: boolean;
    game: Game | null;
    selectedCell: {x: number | null, y: number | null};
    validMovesCache: ValidMovesCache | null;
}

export interface selectedCell {
	x: number | null;
	y: number | null;
}

export interface ShogiPiece {
    piece_type: string;
    promoted: boolean;
    owner: 'b' | 'w';
    id: number;
    position_x: number;
    position_y: number;
}

export interface ParsedSFEN {
    board: (ShogiPiece | null)[][];
    piecesInHand: Record<string, number>;
    playerToMove: 'b' | 'w';
    moveCount: number;
}

interface GameResponse {
    game_id?: number;
    status?: string;
    board_id?: number;
    sfen?: string;
}

interface ValidMovesCache {
    board_state: string;  // SFEN文字列
    moves: {
        [position: string]: string[] | null;  // "7c" -> ["7d", "7e", ...] | null
    };
}

export const useBoardStore = defineStore('board', {
    state: (): BoardState => ({
        shogiData: initializeShogiData(),
        step_number: 0,
        active_player: null,
        board_id: null,
        isError: false,
        game: null,
        selectedCell: {x: null, y: null},
        validMovesCache: null as ValidMovesCache | null,
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

        SetCell(clickedCell: {x: number, y: number} | null) {
            if (clickedCell) {
                this.selectedCell.x = clickedCell.x;
                this.selectedCell.y = clickedCell.y;
            } else {
                this.selectedCell.x = null;
                this.selectedCell.y = null;
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

                const data = response.data as GameResponse;
                
                if (!data.game_id || !data.status || !data.board_id) {
                    throw new Error('Invalid game data: Missing required fields');
                }

                this.updateGameState({
                    id: data.game_id,
                    status: data.status,
                    board_id: data.board_id
                });

                await this.fetchBoard();
            }, 'ゲームの作成に失敗しました');
        },

        // ヘルパーメソッド
        updateGameState(gameData: Pick<Game, 'id' | 'status' | 'board_id'>) {
            this.game = gameData;
            this.board_id = gameData.board_id;
        },

        async fetchBoard() {
            await this.handleAsyncAction(async () => {
                const response = await api.api.v1BoardsDefaultList();
                const parsed = parseSFEN(response.data.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
                this.active_player = parsed.playerToMove;
                this.step_number = parsed.moveCount;
            }, 'ボードの取得に失敗しました');
        },

        // ヘルパーメソッド
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
    
            this.board_id = response.data.board_id ?? null;
            this.shogiData.board = parsed.board;
            this.shogiData.piecesInHand = parsed.piecesInHand;
            this.active_player = parsed.playerToMove;
            this.step_number = parsed.moveCount;
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

        clearValidMovesCache() {
            this.validMovesCache = null;
        },

        updateValidMovesCache() {
            this.validMovesCache = {
                board_state: this.shogiData.sfen,
                moves: {}
            };
        },

        getValidMovesFromCache(position: string): string[] | null {
            // 盤面が変わっていたらキャッシュをクリア
            if (this.validMovesCache?.board_state !== this.shogiData.sfen) {
                this.clearValidMovesCache();
                return null;
            }

            return this.validMovesCache?.moves[position] ?? null;
        },

        async selectPiece(x: number, y: number) {
            const position = `${9-x}${String.fromCharCode(97 + y)}`;
            let validMoves = this.getValidMovesFromCache(position);

            if (!validMoves) {
                if (!this.game?.id || !this.board_id) {
                    throw new Error('Game or board not found');
                }
                const response = await api.api.v1GamesBoardsValidMovesPartialUpdate(
                    this.game.id,
                    this.board_id,
                    { position: position }
                );

                validMoves = response.data.possible_moves ?? null;

                if (!this.validMovesCache) {
                    this.updateValidMovesCache();
                }
                this.validMovesCache!.moves[position] = validMoves;
            }

            this.highlightValidMoves(validMoves);
        },

        highlightValidMoves(moves: string[] | null) {
            // Implementation of highlightValidMoves method
        }
    }
});

const initializeShogiData = (): ShogiData => ({
    board: Array.from({ length: 9 }, () => Array(9).fill(null)) as (ShogiPiece | null)[][],
    piecesInHand: {},
    sfen: ''
});
