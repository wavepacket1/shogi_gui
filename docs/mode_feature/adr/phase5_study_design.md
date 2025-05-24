# フェーズ5: 検討モード設計書

## 概要
- 検討モード（Study）での棋譜再生・分岐検討・コメント機能を実現します。
- MoveHistoryPanel を中心に以下を実装:
  - 任意の局面への移動
  - 新しい分岐の作成
  - 手順の削除
  - コメントの追加
- 対局モードのルール制約は適用しない

## 参照設計
- `frontend_design.md` : UI コンポーネント仕様
- `api_design.md`      : コメント管理 API
- `database_design.md` : コメント用テーブル設計

## 実装要件

### 1. コメント機能
#### 1.1 UI要件
- MoveHistoryPanelの各手順項目にコメントアイコンを表示
- クリックでコメント編集エリアを表示/非表示
- テキストエリアでのマルチライン入力対応
- 自動保存機能（3秒後に保存）
- コメント削除ボタン

#### 1.2 データ構造
```typescript
interface Comment {
  id: number;
  board_history_id: number;
  content: string;
  created_at: string;
  updated_at: string;
}

interface StudyState {
  comments: Record<number, Comment[]>; // board_history_id -> comments[]
  editingCommentId: number | null;
  autoSaveTimer: number | null;
}
```

#### 1.3 API利用
既存のCommentsController APIを活用:
- `GET /api/v1/games/:game_id/board_histories/:move_number/comments`
- `POST /api/v1/games/:game_id/board_histories/:move_number/comments`
- `PUT /api/v1/games/:game_id/board_histories/:move_number/comments/:id`
- `DELETE /api/v1/games/:game_id/board_histories/:move_number/comments/:id`

### 2. 分岐管理機能
#### 2.1 新しい分岐作成
- 各手順項目に「新分岐作成」ボタンを追加
- クリック時に分岐名入力ダイアログを表示
- 分岐名は自動生成（variation-1, variation-2...）または手動入力
- 作成後は新分岐に自動切り替え

#### 2.2 分岐削除
- 分岐セレクタに削除ボタンを追加
- main分岐は削除不可
- 削除確認ダイアログを表示
- 削除後はmain分岐に自動切り替え

#### 2.3 手順削除
- 各手順項目に削除ボタン（ゴミ箱アイコン）を追加
- クリック時に確認ダイアログを表示
- 削除実行後、以降の手順も連動削除
- 分岐にコメントがある場合は警告表示

### 3. 検討モード専用機能
#### 3.1 合法手チェック機能
- 基本将棋ルールに準拠した合法手チェック機能を実装
- 検討モードでは以下の判定を緩和（無効化）:
  - 千日手判定
  - 詰み判定 
  - 時間制限
- 以下の基本ルールは維持:
  - 合法手判定（駒の移動ルール）
  - 王手回避義務
  - 二歩禁止
  - 打ち歩詰め禁止
  - 行き場のない駒の配置禁止

#### 3.1.1 実装方針：既存Validatorクラス活用

**既存Validatorクラスの機能**
- `basic_legal_move?`: 移動・駒打ちの基本ルールチェック
- `legal_move?`: 駒の移動が合法かチェック
- `legal_drop?`: 駒打ちが合法かチェック
- `in_check_for_own_side?`: 王手状態の判定
- `simulate_move`: 指し手の仮実行
- `pawn_drop_mate?`: 打ち歩詰めチェック

**バックエンド実装：新規API追加**
```ruby
# app/controllers/api/v1/legal_moves_controller.rb
class Api::V1::LegalMovesController < ApplicationController
  # POST /api/v1/legal_moves/validate
  def validate
    sfen = params[:sfen]
    move_info = move_info_params.to_h.symbolize_keys
    
    parsed_data = Parser::SfenParser.parse(sfen)
    is_legal = check_legal_for_study_mode(parsed_data, move_info)
    
    render json: { 
      is_legal: is_legal,
      message: is_legal ? '合法手です' : '非合法手です'
    }, status: :ok
  end

  private

  # 検討モード用の合法手チェック（緩和版）
  def check_legal_for_study_mode(parsed_data, move_info)
    board_array, hands, side = parsed_data.values_at(:board_array, :hand, :side)
    
    # 基本的な合法手チェック
    return false unless Validator.basic_legal_move?(board_array, side, move_info)
    
    # 王手回避チェック（自分の王が取られる手は禁止）
    simulated_board = Validator.simulate_move(board_array, hands, side, move_info)
    return false if Validator.in_check_for_own_side?(simulated_board, side)
    
    # 打ち歩詰めチェック（基本ルール維持）
    return false if Validator.pawn_drop_mate?(board_array, hands, side, move_info)
    
    # 検討モードでは以下はチェックしない：
    # - 千日手判定（repetition_check?）
    # - 詰み判定（is_checkmate?）
    
    true
  end
end
```

**フロントエンド実装：StudyModeStore拡張**
```typescript
// stores/studyMode.ts
export const useStudyModeStore = defineStore('studyMode', {
  actions: {
    // 合法手チェック用のAPI呼び出し
    async validateMove(from: Position, to: Position): Promise<boolean> {
      try {
        const response = await fetch('/api/v1/legal_moves/validate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            sfen: this.currentSfen,
            move_info: {
              type: 'move',
              from_row: from.row,
              from_col: from.col,
              to_row: to.row,
              to_col: to.col
            }
          })
        });
        const result = await response.json();
        return result.is_legal;
      } catch (error) {
        console.error('合法手チェックエラー:', error);
        return false; // エラー時は安全側に倒す
      }
    },

    // 駒打ちの合法性チェック
    async validateDrop(piece: string, to: Position): Promise<boolean> {
      try {
        const response = await fetch('/api/v1/legal_moves/validate', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            sfen: this.currentSfen,
            move_info: {
              type: 'drop',
              piece: piece,
              to_row: to.row,
              to_col: to.col
            }
          })
        });
        const result = await response.json();
        return result.is_legal;
      } catch (error) {
        console.error('駒打ちチェックエラー:', error);
        return false;
      }
    }
  }
});
```

**盤面コンポーネント統合**
```vue
<!-- components/StudyBoard.vue -->
<script setup lang="ts">
// ドラッグ&ドロップ時の合法手チェック
const onDrop = async (from: Position, to: Position) => {
  const isLegal = await studyStore.validateMove(from, to);
  
  if (isLegal) {
    // 合法手の場合のみ実行
    await studyStore.executeMove(from, to);
  } else {
    // 非合法手の場合は警告表示
    showMoveError('この手は指せません');
  }
};
</script>
```

**実装メリット**
- 既存コードの再利用：Validatorクラスの豊富な機能を活用
- 段階的な機能制御：検討モードに応じて判定ルールを調整可能
- API設計の一貫性：既存のAPI設計パターンに準拠
- パフォーマンス効率化：サーバーサイドの高速判定処理

**実装ステップ**
1. **バックエンドAPI実装** → LegalMovesController作成
2. **フロントエンドStore拡張** → StudyModeStore作成
3. **UI統合** → 盤面コンポーネントへの合法手チェック統合
4. **テスト実装** → API・フロントエンド双方のテスト
5. **パフォーマンス最適化** → 必要に応じてキャッシュ機能追加

#### 3.2 局面コピー機能
- 現在の局面をSFEN形式でクリップボードにコピー
- 他の将棋ソフトとの連携を想定

### 4. UI/UX改善
#### 4.1 MoveHistoryPanel拡張
```typescript
// 新しいプロパティ
interface MoveHistoryPanelProps {
  gameId: number;
  mode: 'play' | 'edit' | 'study'; // 新しく追加
  allowEdit?: boolean; // 編集可能かどうか
  showComments?: boolean; // コメント表示するか
}
```

#### 4.2 視覚的改善
- コメント有無のアイコン表示
- 分岐ごとの色分け
- 現在の手順のハイライト強化
- ホバー時の操作ボタン表示

## 実装タスク

### フロントエンド
- 1. `MoveHistoryPanel.vue` にコメント表示・編集UI追加
- 2. 分岐作成・削除UI実装
- 3. 手順削除機能実装
- 4. Pinia ストアに検討モード状態管理追加
  - コメント管理
  - 自動保存機能
  - 分岐操作
- 5. 検討モード専用の盤面操作実装
- 6. StudyModeStore拡張（合法手チェック機能）
  - validateMove/validateDropメソッド実装
  - API呼び出し・エラーハンドリング
- 7. 盤面コンポーネントへの合法手チェック統合
  - ドラッグ&ドロップ時の判定
  - 非合法手の警告表示

### バックエンド
- 1. 分岐削除API追加（必要に応じて）
- 2. 手順削除API追加（必要に応じて）
- 3. 検討モード用のバリデーション緩和
- 4. LegalMovesController新規作成
  - 合法手チェックAPI実装
  - 検討モード向け緩和ルール適用
  - 既存Validatorクラス活用
- 5. ルーティング追加（/api/v1/legal_moves/validate）

### 共通
- 1. 型定義の拡張（Comment, StudyState等）
- 2. エラーハンドリングの強化
- 3. 合法手チェック関連の型定義追加

## テスト要件
- コンポーネント単体テスト (Jest/Vitest)
  - コメント編集機能
  - 分岐操作機能
  - 自動保存機能
  - 合法手チェック機能（StudyModeStore）
- Pinia ストアユニットテスト
  - コメント状態管理
  - 分岐状態管理
  - 合法手チェックAPI呼び出し
- API リクエストスペック (RSpec)
  - 既存コメントAPI動作確認
  - 新規API（分岐削除等）
  - LegalMovesController API
    - 基本的な合法手判定
    - 検討モード向け緩和ルール
    - エラーハンドリング
- E2E テスト (Cypress)
  - 検討モード全体フロー
  - コメント作成・編集・削除
  - 分岐作成・切り替え・削除
  - 合法手チェック統合動作

## 実装優先度
1. **Phase 1**: コメント機能実装（既存APIを活用）
2. **Phase 2**: 分岐作成・削除UI実装
3. **Phase 3**: 手順削除機能実装
4. **Phase 4**: 合法手チェック機能実装（既存Validatorクラス活用）
   - LegalMovesController API作成
   - StudyModeStore拡張
   - 盤面コンポーネントへの統合
5. **Phase 5**: 検討モード専用機能（局面コピー等）
6. **Phase 6**: UI/UX改善・パフォーマンス最適化 