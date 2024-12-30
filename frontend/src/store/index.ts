import { defineStore } from 'pinia';
import { Api } from '@/services/api';
import { parseSFEN } from '@/utils/sfenParser';

export interface Game {
    id: number;
    name?: string;
    status: string;
    board_id: number;
}

export interface ShogiData {
    board: (ShogiPiece | null)[][];
    piecesInHand: Record<string, number>;
}

export interface BoardState {
    shogiData: ShogiData;
    step_number: number;
    active_player: 'b' | 'w' | null;
    board_id: number | null;
    isError: boolean;
    game: Game | null;
    selectedCell: {x: number|null, y: number|null};
    game_id: number | null;
}

export interface selectedCell {
	x: number|null;
	y: number|null;
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
    id?: number;
    status?: string;
}

const api = new Api({ baseUrl: 'http://localhost:3000' });

export const useBoardStore = defineStore('board', {
    state: (): BoardState => ({
        shogiData: initializeShogiData(),
        step_number: 0,
        active_player: null,
        board_id: null,
        isError: false, // エラーの有無を管理
        game_id: null,
        selectedCell: {x: null, y: null},
        game: null
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
    
        async movePiece(game_id: number, board_id: number, X: number, Y: number) {
            await this.handleAsyncAction(async () => {
                if (this.selectedCell.x === null || this.selectedCell.y === null) {
                    throw new Error('No piece selected');
                }

                const convertPosition = (x: number, y: number) => ({
                    x: 9 - x,
                    y: String.fromCharCode(97 + y) // 'a'-'i' for 1-9
                });
                
                const from = convertPosition(this.selectedCell.x, this.selectedCell.y);
                const to = convertPosition(X, Y);
                const usiMove = `${from.x}${from.y}${to.x}${to.y}`;

                const response = await api.api.v1GamesBoardsMovePartialUpdate(
                    game_id, 
                    board_id, 
                    { move: usiMove }
                );

                if (!response.data.sfen) {
                    throw new Error('SFEN data is missing');
                }

                const parsed = parseSFEN(response.data.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
                this.SetCell(null); // 選択状態をリセット
            }, '駒の移動に失敗しました');
        },

        async createGame() {
            await this.handleAsyncAction(async () => {
                const response = await api.api.v1GamesCreate({ status: 'active' });
                console.log('Game creation response:', response.data); // デバッグ用

                const data = response.data as GameResponse;
                
                if (!data.id || !data.status) {
                    throw new Error('Invalid game data: Missing required fields');
                }

                // game_idを設定
                this.game_id = data.id;  // この行を追加

                // ゲーム情報の更新
                this.updateGameState({
                    id: data.id,
                    status: data.status,
                    board_id: data.id  // 一時的にidを使用
                });

                console.log('Game state after update:', {  // デバッグ用
                    game_id: this.game_id,
                    board_id: this.board_id,
                    game: this.game
                });

                // 将棋盤の状態を更新
                await this.fetchBoard();
            }, 'ゲームの作成に失敗しました');
        },

        // ヘルパーメソッド
        updateGameState(gameData: Pick<Game, 'id' | 'status' | 'board_id'>) {
            this.game = gameData;
            this.board_id = gameData.board_id;
        },

        updateBoardState(sfen: string) {
            const parsed = parseSFEN(sfen);
            this.shogiData.board = parsed.board;
            this.shogiData.piecesInHand = parsed.piecesInHand;
            this.active_player = parsed.playerToMove;
            this.step_number = parsed.moveCount;
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
        }
    }
});

const initializeShogiData = (): ShogiData => ({
    board: Array.from({ length: 9 }, () => Array(9).fill(null)) as (ShogiPiece | null)[][],
    piecesInHand: {},
});
