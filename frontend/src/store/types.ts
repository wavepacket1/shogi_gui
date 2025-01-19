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
    is_checkmate: boolean;
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
