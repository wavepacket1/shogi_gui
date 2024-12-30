import type { ParsedSFEN } from '@/store';

export interface ShogiPiece {
    piece_type: string;
    promoted: boolean;
    owner: 'b' | 'w';
    id: number;
    position_x: number;
    position_y: number;
}

export type ShogiBoard = (ShogiPiece | null)[][];

export interface ShogiSFEN {
    board: ShogiBoard;
    playerToMove: 'b' | 'w';
    piecesInHand: { [key: string]: number };
    moveCount: number;
}

export function parseSFEN(sfen: string): ParsedSFEN {
    const parts = sfen.split(' ');
    if (parts.length < 4) {
        throw new Error('Invalid SFEN format');
    }

    const [boardPart, playerToMove, piecesInHandPart, moveCountPart] = parts;

    const board: ShogiBoard = Array.from({ length: 9 }, () => Array(9).fill(null));

    const rows = boardPart.split('/');
    if (rows.length !== 9) {
        throw new Error('Invalid SFEN board format');
    }

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
                board[y][x] = { 
                    piece_type, 
                    promoted, 
                    owner,
                    id: 0,
                    position_x: x,
                    position_y: y
                };
                x++;
            }
        }
    });

    //持ち駒の解析
    let piecesInHand: { [key: string]: number } = {};
    console.log('piecesInHandPart:', piecesInHandPart);
    if (piecesInHandPart !== '-') {
        const regex = /(\d*)([PRBLNSGKprblnsgk])/g;
        let match;
        while ((match = regex.exec(piecesInHandPart)) !== null) {
            const count = match[1] ? parseInt(match[1], 10) : 1;
            const piece = match[2];
            piecesInHand[piece] = (piecesInHand[piece] || 0) + count;
        }
    }

    const moveCount = parseInt(moveCountPart, 10);

    return {
        board,
        playerToMove: playerToMove as 'b' | 'w',
        piecesInHand,
        moveCount,
    };
}