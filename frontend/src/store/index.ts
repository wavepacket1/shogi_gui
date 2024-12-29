import { defineStore } from 'pinia';
import { Api } from '@/services/api';
import { parseSFEN } from '@/utils/sfenParser';

interface Game {
    id: number;
    name: string;
    status: string;
}

interface ShogiData {
    board: (ShogiPiece | null)[][];
    piecesInHand: Record<string, number>;
}

interface BoardState {
    shogiData: ShogiData;
    step_number: number;
    active_player: 'b' | 'w' | null;
    board_id: number | null;
    isError: boolean;
    game: Game | null;
}

interface selectedCell {
	x: number|null;
	y: number|null;
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
	SelectedCell: {x: null, y: null}
    }),
    actions: {
        async handleAsyncAction(asyncAction: () => Promise<void>, errorMessage?: string) {
            this.isError = false;

try {
                await asyncAction();
            } catch (error: unknown) {
                if(error instanceof Error) {
                    console.error(errorMessage || 'エラーが発生しました', error.message);
                } else {
                    console.error(errorMessage || '未知のエラーが発生しました', error);
                }
                this.isError = true;
            }
        },

        SetCell(piece: string, x: number, y: number) {
            if (piece) {
                this.selectedCell.x = ClickedCell.x;
                this.selectedCell.y = ClickedCell.y;
            }
        },
    
        async movePiece(game_id: string, board_id: number,  X: number, Y: number) {
            await this.handleAsyncAction(async () => {
                const response = await api.api.v1GamesBoardsMovePartialUpdate(game_id, board_id, { move: `${X}${Y}` });
                const parsed = parseSFEN(response.data.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
            }, '駒の移動に失敗しました');
        },

        async createGame() {
            await this.handleAsyncAction(async () => {
                const response = await api.api.v1GamesCreate({ status: 'active' });
                this.game = response.data;
                this.board_id = response.data.board_id;
                const parsed = parseSFEN(response.data.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
                this.active_player = parsed.playerToMove;
                this.step_number = parsed.moveCount;
            }, 'ゲームの作成に失敗しました');
        },

        async getDefaultBoard() {
            await this.handleAsyncAction(async () => {
                const response = await api.api.v1BoardsDefaultList();
                const parsed = parseSFEN(response.data.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
            }, 'デフォルトボードの取得に失敗しました');
        }
    }
});

const initializeShogiData = (): ShogiData => ({
    board: Array.from({ length: 9 }, () => Array(9).fill(null)) as (ShogiPiece | null)[][],
    piecesInHand: {},
});
