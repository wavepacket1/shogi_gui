// 駒の種類の型定義
export type PieceType = 
  'P' | 'L' | 'N' | 'S' | 'G' | 'B' | 'R' | 'K' | // 先手駒
  'p' | 'l' | 'n' | 's' | 'g' | 'b' | 'r' | 'k' | // 後手駒
  '+P' | '+L' | '+N' | '+S' | '+B' | '+R' | // 先手成駒
  '+p' | '+l' | '+n' | '+s' | '+b' | '+r' | // 後手成駒
  null; // 空のマス

// nullを含まないPieceTypeを定義
export type NonNullPieceType = Exclude<PieceType, null>;

// プレイヤー側の型定義
export type PlayerSide = 'b' | 'w'; // b=先手(black), w=後手(white)

// ゲームモードの型定義
export type GameMode = 'play' | 'edit' | 'study';

// 位置の型定義
export interface Position {
  row: number;
  col: number;
}

// 移動情報の型定義
export interface MoveInfo {
  from: Position;
  to: Position;
  piece: PieceType;
}

// 盤面状態の型定義
export interface BoardState {
  board: (PieceType)[][];
  currentSide: PlayerSide;
  gameId: number | null;
  unsavedChanges: boolean;
  piecesInHand: Record<NonNullPieceType, number>; // 持ち駒 - nullを除外
}

// ドラッグ中の駒情報
export interface DraggingPiece {
  piece: PieceType;
  row: number;
  col: number;
}

// コメント情報の型定義（検討モード用）
export interface Comment {
  id: number;
  board_history_id: number;
  content: string;
  created_at: string;
  updated_at: string;
}

// 検討モード状態の型定義
export interface StudyState {
  comments: Record<string | number, Comment[]>; // board_history_id -> comments[]
  editingCommentId: number | null;
  autoSaveTimer: ReturnType<typeof setTimeout> | null;
  currentGameId: number | null;
  currentMoveNumber: number | null;
  currentBranch: string;
  isLoadingComments: boolean;
}

// MoveHistoryPanel用のプロパティ型定義
export interface MoveHistoryPanelProps {
  gameId: number;
  mode: GameMode;
  allowEdit?: boolean;
  showComments?: boolean;
}

// 成れる駒の判定用マップ
export const promotablePieces: PieceType[] = [
  'P', 'L', 'N', 'S', 'B', 'R', 
  'p', 'l', 'n', 's', 'b', 'r'
];

// 成り駒と通常駒の変換マップ
export const promotionMap: Record<NonNullPieceType, PieceType> = {
  'P': '+P', '+P': 'P',
  'L': '+L', '+L': 'L',
  'N': '+N', '+N': 'N',
  'S': '+S', '+S': 'S',
  'B': '+B', '+B': 'B',
  'R': '+R', '+R': 'R',
  'p': '+p', '+p': 'p',
  'l': '+l', '+l': 'l',
  'n': '+n', '+n': 'n',
  's': '+s', '+s': 's',
  'b': '+b', '+b': 'b',
  'r': '+r', '+r': 'r',
  'G': 'G', 'g': 'g', // 金は成れない
  'K': 'K', 'k': 'k', // 玉は成れない
} as Record<NonNullPieceType, PieceType>; 