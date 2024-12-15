import { defineStore } from 'pinia';
import { createGameAPI, updatePositionAPI, getDefaultBoardAPI } from '@/services/api';
import { parseSFEN } from '@/utils/sfenParser';

interface Game {
    id: number;
    name: string;
    status: string;
}

interface ShogiPiece {
    id: number;
    position_x: number;
    position_y: number;
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

export const useBoardStore = defineStore('board', {
    state: (): BoardState => ({
        shogiData: initializeShogiData(),
        step_number: 0,
        active_player: null,
        board_id: null,
        isError: false, // エラーの有無を管理
        game: null as any,
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

        findPiece(pieceId: number): ShogiPiece | undefined {
            for (const row of this.shogiData.board) {
                const piece = row.find((p) => p?.id === pieceId);
                if (piece) {
                    return piece;
                }
            }
            return undefined;
        },

        updatePosition(pieceId: number, x: number, y: number) {
            const piece = this.findPiece(pieceId);
            if (piece) {
                piece.position_x = x;
                piece.position_y = y;
            }
        },
    
        async movePiece(pieceId: number, toX: number, toY: number) {
            await this.handleAsyncAction(async () => {
                await updatePositionAPI(pieceId, toX, toY);
                this.updatePosition(pieceId, toX, toY);
            }, '駒の移動に失敗しました');
        },

        async createGame() {
            await this.handleAsyncAction(async () => {
                const response = await createGameAPI('新しいゲーム');
                this.game = response.data.game;
                this.board_id = response.data.board.id;
                const parsed = parseSFEN(response.data.board.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
                this.active_player = parsed.playerToMove;
                this.step_number = parsed.moveCount;
            }, 'ゲームの作成に失敗しました');
        },

        async getDefaultBoard() {
            await this.handleAsyncAction(async () => {
                const response = await getDefaultBoardAPI();
                const parsed = parseSFEN(response.sfen);
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