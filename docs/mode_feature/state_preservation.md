# モード切替時の状態保持仕様

## 1. 対局モード → 編集モード

### 保存する情報
- 現在の局面（SFEN形式）
- 手番情報
- 手順履歴
- 経過時間

### 復元時の処理
- 編集前の局面を`initial_sfen`として保存
- 編集セッション開始時のメタデータとして保存
- 編集キャンセル時に元の状態に復帰可能

## 2. 対局モード → 検討モード

### 保存する情報
- 全ての手順履歴
- 現在の表示手数
- コメント情報
- 分岐情報

### 復元時の処理
- 検討終了時に選択された局面から新規対局として再開
- それまでの手順は検討履歴として保持

## 3. 編集モード → 対局モード

### 保存する情報
- 編集完了時の局面
- 設定された手番
- 編集履歴（アンドゥ/リドゥ用）

### 復元時の処理
- 編集した局面を初期局面として設定
- 新規対局として開始
- 編集履歴は別途保存

## 4. 編集モード → 検討モード

### 保存する情報
- 編集完了時の局面
- 編集履歴
- 設定された手番

### 復元時の処理
- 編集局面を検討開始局面として設定
- 編集履歴を検討モードでも参照可能に

## 5. 検討モード → 対局モード

### 保存する情報
- 現在の局面
- それまでの検討内容
- 分岐情報
- コメント

### 復元時の処理
- 選択された局面から新規対局開始
- 検討情報は参照用として保持

## 6. 検討モード → 編集モード

### 保存する情報
- 現在の局面
- 検討履歴
- コメント
- 分岐情報

### 復元時の処理
- 現在の局面を編集モードで開く
- 検討情報は一時保存

## 7. 状態管理の実装

### フロントエンド（Pinia Store）
```typescript
interface ModeState {
  previousMode: GameMode | null;
  preservedState: {
    sfen: string;
    moveHistory: MoveHistory[];
    comments: Comment[];
    branches: Branch[];
    editHistory: EditHistory[];
  } | null;
  transitionMetadata: {
    timestamp: string;
    reason: string;
    preservedStateKey: string;
  } | null;
}
```

### バックエンド（Ruby）
```ruby
class ModeTransition
  include ActiveModel::Model
  
  attr_accessor :from_mode, :to_mode, :game_id
  attr_accessor :preserved_state, :metadata
  
  validates :from_mode, :to_mode, :game_id, presence: true
  validates :from_mode, :to_mode, inclusion: { in: Game::VALID_MODES }
  
  def execute
    Game.transaction do
      # モード切替の実行
      # 状態の保存と復元
      # トランザクション管理
    end
  end
end
```

## 8. エラー処理

### 考慮すべきエラーケース
1. 未保存の変更がある状態でのモード切替
2. 不正な局面でのモード切替
3. 権限のないモードへの切替
4. 同時編集によるコンフリクト
5. ネットワークエラーによる状態の不整合

### エラー処理方針
1. モード切替前の変更確認
2. バリデーションの実施
3. ロールバック機能の実装
4. 競合解決のUIの提供
5. 自動保存機能の実装

## 9. パフォーマンス考慮事項

### メモリ管理
- 不要な状態の適切な破棄
- 大きな履歴データの遅延読み込み
- キャッシュの適切な利用

### 状態の永続化
- 定期的な自動保存
- 重要な操作前の状態保存
- クラッシュ復旧機能

## 10. セキュリティ

### アクセス制御
- モードごとの権限チェック
- 状態変更の記録
- 監査ログの保持

### データ保護
- 機密情報の適切な管理
- 権限のない状態アクセスの防止
- セッション管理の徹底