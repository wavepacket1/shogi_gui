import { defineStore } from 'pinia';
import { GamesApi, BoardsApi, MovesApi } from '@/services/api/api';
import { parseSFEN } from '@/utils/sfenParser';
import { Configuration } from '@/services/api/configuration';

const config = new Configuration({ basePath: 'http://localhost:3000' });
const gamesApi = new GamesApi(config);
const boardsApi = new BoardsApi(config);
const movesApi = new MovesApi(config);

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
    game_id?: number;
    status?: string;
    board_id?: number;
    sfen?: string;
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

                const response = await movesApi.apiV1GamesGameIdBoardsBoardIdMovePatch(
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
                this.active_player = parsed.playerToMove;
                this.step_number = parsed.moveCount;
            
                this.SetCell(null); // 選択状態をリセット
            }, '駒の移動に失敗しました');
        },

        async createGame() {
            await this.handleAsyncAction(async () => {
                const response = await gamesApi.apiV1GamesPost({ status: 'active' });
                console.log('API Response:', response.data);

                const data = response.data as GameResponse;
                
                if (!data.game_id || !data.status || !data.board_id) {
                    console.log('Missing fields:', {
                        game_id: data.game_id,
                        status: data.status,
                        board_id: data.board_id
                    });
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
                const response = await boardsApi.apiV1BoardsDefaultGet();
                const parsed = parseSFEN(response.data.sfen);
                this.shogiData.board = parsed.board;
                this.shogiData.piecesInHand = parsed.piecesInHand;
                this.active_player = parsed.playerToMove;
                this.step_number = parsed.moveCount;
                console.log(this.step_number);
            }, 'ボードの取得に失敗しました');
        }
    }
});

const initializeShogiData = (): ShogiData => ({
    board: Array.from({ length: 9 }, () => Array(9).fill(null)) as (ShogiPiece | null)[][],
    piecesInHand: {},
});
