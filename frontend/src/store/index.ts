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
                const response = await api.api.v1GamesBoardsMovePartialUpdate(game_id, board_id, { move: `${X}${Y}` });
                if (!response.data.sfen) throw new Error('SFEN data is missing');
                const parsed = parseSFEN(response.data.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
            }, '駒の移動に失敗しました');
        },

        async createGame() {
            await this.handleAsyncAction(async () => {
                const response = await api.api.v1GamesCreate({ status: 'active' });
                if (!response.data.id || !response.data.status || !response.data.board_id || !response.data.sfen) {
                    throw new Error('Invalid game data');
                }
                this.game = {
                    id: response.data.id,
                    status: response.data.status,
                    board_id: response.data.board_id
                };
                this.board_id = response.data.board_id;
                const parsed = parseSFEN(response.data.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
                this.active_player = parsed.playerToMove;
                this.step_number = parsed.moveCount;
            }, 'ゲームの作成に失敗しました');
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
