export enum Player {
    Black = 'b',
    White = 'w'
}

export enum GameMode {
    PLAY = 'play',
    EDIT = 'edit',
    STUDY = 'study'
}

export interface Game {
    id: number;
    name?: string;
    status: string;
    mode?: GameMode;
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
    boardHistories: BoardHistory[];
    currentBranch: string;
    branches: string[];
    currentMoveIndex: number;
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

export interface BoardHistory {
    id: number;
    game_id: number;
    move_number: number;
    branch: string;
    board_state: string;
    pieces_in_hand: { [key: string]: number };
    /** 前局面からの指し手情報（SFEN形式）例：7g7f, P*3d, 8h2b+ */
    move_sfen?: string;
    /** @deprecated 今後はmove_sfenとnotationを使用してください */
    last_move_from: string | null;
    /** @deprecated 今後はmove_sfenとnotationを使用してください */
    last_move_to: string | null;
    /** @deprecated 今後はmove_sfenとnotationを使用してください */
    last_move_piece: string | null;
    /** @deprecated 今後はmove_sfenとnotationを使用してください */
    last_move_player: string | null;
    /** @deprecated 今後はmove_sfenとnotationを使用してください */
    last_move_promoted: boolean;
    /** 棋譜表記（例：「▲7六歩」「△8四銀」）。 */
    notation: string;
    created_at: string;
    updated_at: string;
}

export interface BranchesResponse {
    branches: string[];
}

export interface NavigateResponse {
    game_id: number;
    board_id: number;
    move_number: number;
    sfen: string;
    /** 前局面からの指し手情報（SFEN形式） */
    move_sfen?: string | null;
    /** 棋譜表記（日本語形式） */
    notation?: string | null;
}
