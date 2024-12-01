import { defineStore } from 'pinia';
import { getBoardSFEN } from '@/services/api';
import { parseSFEN, ShogiSFEN } from '@/utils/sfenParser';

export const useBoardStore = defineStore('board', {
    state: () => ({
        shogiData: {
            board: Array.from({ length: 9 }, () => Array(9).fill(null)), // 初期化済みの9x9ボード
            piecesInHand: {} as Record<string, number>, // piecesInHandも初期化
        },
        isError: false, // エラーの有無を管理
    }),
    actions: {
        async fetchBoard(id: number) {
            try {
                this.isError = false;
                const response = await getBoardSFEN(id);
                const parsed = parseSFEN(response.data);
                if (parsed) {
                    this.shogiData.board = parsed.board;
                    this.shogiData.piecesInHand = parsed.piecesInHand;
                } else {
                    console.error('SFENの解析に失敗しました');
                    this.isError = true;
                }
            } catch (error) {
                console.error('ボードの取得に失敗しました', error);
                this.isError = true;
            }
        },
        updatePiecePosition(pieceId: number, x: number, y: number) {
            if (this.shogiData.board) {
                for (const row of this.shogiData.board) {
                    const piece = row.find((p) => p?.id === pieceId);
                    if (piece) {
                        piece.position_x = x;
                        piece.position_y = y;
                        break; // 駒が見つかったらそれ以上のループは不要
                    }
                }
            }
        },
        async movePiece(pieceId: number, toX: number, toY: number) {
            try {
                this.isError = false;
                // APIエンドポイントにリクエストを送信
                await updatePiecePositionAPI(pieceId, toX, toY); // updatePiecePositionAPIはAPI呼び出し関数
                this.updatePiecePosition(pieceId, toX, toY);
            } catch (error) {
                console.error('駒の移動に失敗しました', error);
                this.isError = true;
            }
        }
    }
});
