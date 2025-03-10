export enum Player {
    Black = 'b',
    White = 'w'
}

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
    stepNumber: number;
    activePlayer: Player | null;
    board_id: number | null;
    isError: boolean;
    is_checkmate: boolean;
    is_repetition: boolean;
    is_repetition_check: boolean;
    is_check_entering_king: boolean | null;
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
    owner: Player;
    id: number;
    position_x: number;
    position_y: number;
}

export interface ParsedSFEN {
    board: (ShogiPiece | null)[][];
    piecesInHand: Record<string, number>;
    playerToMove: Player;
    moveCount: number;
}

export interface GameResponse {
    game_id?: number;
    status?: string;
    board_id?: number;
    sfen?: string;
}

export interface ValidMovesCache {
    board_state: string;  // SFEN文字列
    moves: {
        [position: string]: string[] | null;  // "7c" -> ["7d", "7e", ...] | null
    };
}
