export interface ShogiPiece {
    piece_type: string;
    promoted: boolean;
    owner: 'b' | 'w';
}

export type ShogiBoard = (ShogiPiece | null)[][];

export interface ShogiSFEN {
    board: ShogiBoard;
    playerToMove: 'b' | 'w';
    piecesInHand: { [key: string]: number };
    moveCount: number;
}

export const parseSFEN = (sfen: string): ShogiSFEN | null => {
    const parts = sfen.split(' ');
    if (parts.length < 4) return null;

    const [boardPart, playerToMove, piecesInHandPart, moveCountPart] = parts;

    const board: ShogiBoard = Array.from({ length: 9 }, () => Array(9).fill(null));

    const rows = boardPart.split('/');
    if (rows.length !== 9) return null;

    rows.forEach((row, y) => {
        let x = 0;
        for (let i = 0; i < row.length; i++) {
            const char = row[i];
            if (/\d/.test(char)) {
                x += parseInt(char, 10);
            } else {
                let promoted = false;
                let piece_type = char;
                if (char === '+') {
                    promoted = true;
                    i++;
                    piece_type = row[i];
                }
                const owner = piece_type === piece_type.toUpperCase() ? 'b' : 'w';
                board[y][x] = { piece_type, promoted, owner};
                x++;
            }
        }
    });

    //持ち駒の解析
    let piecesInHand: { [key: string]: number } = {};
    if (piecesInHandPart !== '-') {
        const regex = /([PRBLNSGKprblnsgk])(\d*)/g;
        let match;
        while ((match = regex.exec(piecesInHandPart)) !== null) {
            const piece = match[1];
            const count = match[2] ? parseInt(match[2], 10) : 1;
            if (/[A-Z]/.test(piece)) {
                piecesInHand[piece] = (piecesInHand[piece] || 0) + count;
            } else {
                const upperPiece = piece.toUpperCase();
                piecesInHand[upperPiece] = (piecesInHand[upperPiece] || 0) + count;
            }
        }
    }

    const moveCount = parseInt(moveCountPart, 10);

    return {
        board,
        playerToMove: playerToMove as 'b' | 'w',
        piecesInHand,
        moveCount,
    };
};