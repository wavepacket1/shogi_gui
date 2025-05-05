import { defineStore } from 'pinia';
import axios from 'axios';
import { 
  PieceType, 
  PlayerSide, 
  MoveInfo, 
  BoardState,
  promotionMap,
  promotablePieces,
  NonNullPieceType
} from '../types/shogi';

export const useBoardEditStore = defineStore('boardEdit', {
  state: (): BoardState => ({
    board: Array(9).fill(null).map(() => Array(9).fill(null)), // 9x9の将棋盤
    currentSide: 'b' as PlayerSide, // 'b'=先手(black), 'w'=後手(white)
    gameId: null,
    unsavedChanges: false,
    piecesInHand: {} as Record<NonNullPieceType, number>
  }),
  
  actions: {
    /**
     * 駒の移動
     * @param moveInfo 移動情報
     */
    movePiece(moveInfo: MoveInfo): void {
      const { from, to, piece } = moveInfo;
      
      // 駒をそのまま移動（所有権を維持）
      this.board[to.row][to.col] = piece;
      
      // 元の位置にあった駒を消去（ドラッグ元の駒を消す）
      if (from.row !== undefined && from.col !== undefined) {
        this.board[from.row][from.col] = null;
      }
      
      // デバッグログ
      console.log('駒移動完了', {
        piece,
        moveTo: `${to.row}-${to.col}`,
        currentBoard: JSON.stringify(this.board),
      });
      
      this.unsavedChanges = true;
    },
    
    /**
     * 駒の削除（駒台に移動）
     * @param row 行インデックス
     * @param col 列インデックス
     */
    removePiece(row: number, col: number): void {
      const piece = this.board[row][col];
      
      if (piece !== null) {
        // 駒が成っている場合は、成っていない状態に戻す
        let baseForm = piece;
        if (piece.startsWith('+')) {
          const secondChar = piece.charAt(1);
          baseForm = secondChar === secondChar.toUpperCase() ? secondChar.toUpperCase() : secondChar.toLowerCase();
        }
        
        // 駒の所有権を反対にする（相手の駒として持ち駒に追加）
        if (typeof baseForm === 'string') {
          // 大文字(先手)の駒は小文字(後手)に、小文字の駒は大文字に変換
          const isUpperCase = baseForm === baseForm.toUpperCase();
          const ownedPiece = isUpperCase ? 
            baseForm.toLowerCase() as NonNullPieceType : 
            baseForm.toUpperCase() as NonNullPieceType;
            
          // 持ち駒を増やす
          this.piecesInHand[ownedPiece] = (this.piecesInHand[ownedPiece] || 0) + 1;
        }
        
        // 盤面から駒を削除
        this.board[row][col] = null;
        // 変更があったことをマーク
        this.unsavedChanges = true;
      }
    },
    
    /**
     * 成り/不成り切り替え
     * @param row 行インデックス
     * @param col 列インデックス
     */
    togglePromotion(row: number, col: number): void {
      const piece = this.board[row][col];
      if (!piece) return;
      
      // 成れる駒かチェック
      if (promotablePieces.includes(piece)) {
        // 成り/成らずの切り替え
        this.board[row][col] = promotionMap[piece];
        this.unsavedChanges = true;
      }
    },
    
    /**
     * 手番の切り替え
     */
    toggleCurrentSide(): void {
      this.currentSide = this.currentSide === 'b' ? 'w' : 'b';
    },
    
    /**
     * 駒の取得
     * @param row 行インデックス
     * @param col 列インデックス
     * @returns 駒の種類
     */
    getPieceAt(row: number, col: number): PieceType {
      return this.board[row][col];
    },
    
    /**
     * 持ち駒から駒を使用する
     * @param piece 使用する駒の種類
     */
    usePieceFromHand(piece: NonNullPieceType): void {
      // 持ち駒の数を確認
      if (this.piecesInHand[piece] && this.piecesInHand[piece] > 0) {
        // 持ち駒を減らす
        this.piecesInHand[piece]--;
        // 変更があったことをマーク
        this.unsavedChanges = true;
      }
    },
    
    /**
     * 駒が成れるかどうか判定
     * @param piece 駒の種類
     * @returns 成れるならtrue
     */
    canPromote(piece: PieceType): boolean {
      if (!piece) return false;
      return promotablePieces.includes(piece);
    },
    
    /**
     * 盤面をSFEN形式に変換
     * @returns SFEN文字列
     */
    toSfen(): string {
      let sfen = '';
      let emptyCount = 0;
      
      // 盤面部分の変換
      for (let row = 0; row < 9; row++) {
        for (let col = 0; col < 9; col++) {
          const piece = this.board[row][col];
          if (piece) {
            // 空マスがあれば先に数字を追加
            if (emptyCount > 0) {
              sfen += emptyCount.toString();
              emptyCount = 0;
            }
            sfen += piece;
          } else {
            emptyCount++;
          }
        }
        // 行の終わりで空マスカウントを処理
        if (emptyCount > 0) {
          sfen += emptyCount.toString();
          emptyCount = 0;
        }
        // 最後の行でなければ区切り文字を追加
        if (row < 8) {
          sfen += '/';
        }
      }
      
      // 手番、持ち駒、手数の追加
      // 今回はシンプルに実装（実際には持ち駒も管理する必要あり）
      sfen += ` ${this.currentSide} - 1`;
      
      return sfen;
    },
    
    /**
     * ゲームIDを設定
     * @param id ゲームID
     */
    setGameId(id: number): void {
      this.gameId = id;
    },
    
    /**
     * 盤面の保存（APIへの送信）
     * @returns API応答
     */
    async saveBoard(): Promise<any> {
      if (!this.gameId) {
        throw new Error('ゲームIDが指定されていません');
      }
      
      try {
        const response = await axios.post('/api/v1/boards', {
          board: {
            game_id: this.gameId,
            sfen: this.toSfen()
          },
          mode: 'edit'
        });
        
        if (response.status === 201) {
          this.unsavedChanges = false;
          return response.data;
        }
      } catch (error) {
        console.error('盤面の保存に失敗しました', error);
        throw error;
      }
    },
    
    /**
     * 平手の初期盤面を設定
     */
    initializeHirateBoardSFEN(): void {
      // 9x9の空の盤面を作成
      this.board = Array(9).fill(null).map(() => Array(9).fill(null));
      
      // 平手の配置 - 先手（下側）
      // 9段目: 香、桂、銀、金、玉、金、銀、桂、香
      this.board[8][0] = 'L';
      this.board[8][1] = 'N';
      this.board[8][2] = 'S';
      this.board[8][3] = 'G';
      this.board[8][4] = 'K';
      this.board[8][5] = 'G';
      this.board[8][6] = 'S';
      this.board[8][7] = 'N';
      this.board[8][8] = 'L';
      
      // 8段目: 飛(2行目)、角(8行目)
      this.board[7][1] = 'R';
      this.board[7][7] = 'B';
      
      // 7段目: 歩兵
      for (let i = 0; i < 9; i++) {
        this.board[6][i] = 'P';
      }
      
      // 平手の配置 - 後手（上側）
      // 1段目: 香、桂、銀、金、玉、金、銀、桂、香
      this.board[0][0] = 'l';
      this.board[0][1] = 'n';
      this.board[0][2] = 's';
      this.board[0][3] = 'g';
      this.board[0][4] = 'k';
      this.board[0][5] = 'g';
      this.board[0][6] = 's';
      this.board[0][7] = 'n';
      this.board[0][8] = 'l';
      
      // 2段目: 角(2行目)、飛(8行目)
      this.board[1][1] = 'b';
      this.board[1][7] = 'r';
      
      // 3段目: 歩兵
      for (let i = 0; i < 9; i++) {
        this.board[2][i] = 'p';
      }
      
      // 先手番に設定
      this.currentSide = 'b';
      
      this.unsavedChanges = false;
    },
    
    /**
     * 初期盤面に設定
     */
    initializeEmptyBoard(): void {
      // 平手の局面で初期化
      this.initializeHirateBoardSFEN();
      
      this.unsavedChanges = false;
    }
  }
}); 