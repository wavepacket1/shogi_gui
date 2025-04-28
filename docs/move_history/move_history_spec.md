# 将棋GUIの手の履歴機能仕様書

## 概要

将棋GUIアプリケーションにおいて、対局中の局面履歴を管理し、過去の局面に戻ったり、分岐を作成したりする機能を実装します。これにより、ユーザーは対局の流れを確認したり、異なる手順を検討したりすることができます。

## 機能要件

### 基本機能

1. **対局履歴の表示**
   - 対局中の全ての手を時系列順に表示する
   - 現在の局面がどの手に対応しているかを明示する
   - 駒の動きを棋譜形式（例: ▲7六歩、△3四歩）で表示する

2. **局面の移動**
   - 任意の手数に移動できる
   - 一手ずつ前後に移動できる
   - 最初または最後の手に直接移動できる

3. **分岐の管理**
   - 過去の局面から異なる手を指した場合に分岐を作成する
   - 複数の分岐を管理し、切り替えることができる
   - 分岐ごとの履歴を表示する

## 技術仕様

### データベース設計

#### board_historiesテーブル

| フィールド   | データ型      | 説明                                  |
|--------------|---------------|---------------------------------------|
| id           | integer       | 主キー                                |
| game_id      | integer       | Game テーブルへの外部キー              |
| sfen         | string        | 局面のSFEN表記                        |
| move_number  | integer       | 手数（0から始まる）                    |
| branch       | string        | 分岐名（デフォルト: "main"）           |
| created_at   | datetime      | 作成日時                              |
| updated_at   | datetime      | 更新日時                              |

**インデックス**:
- game_id, move_number, branch の組み合わせに一意性制約

![ER図](./er_diagram.png)

### API設計

#### 1. 局面履歴の取得

**エンドポイント**: `GET /api/v1/games/:game_id/board_histories`

**パラメータ**:
- `game_id`: ゲームID (必須)
- `branch`: 分岐名 (任意、デフォルト: "main")

**レスポンス**:
```json
[
  {
    "id": 1,
    "game_id": 123,
    "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL b - 0",
    "move_number": 0,
    "branch": "main",
    "created_at": "2023-09-01T12:00:00Z",
    "updated_at": "2023-09-01T12:00:00Z",
    "notation": null
  },
  {
    "id": 2,
    "game_id": 123,
    "sfen": "lnsgkgsnl/1r5b1/ppppppppp/9/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL w - 1",
    "move_number": 1,
    "branch": "main",
    "created_at": "2023-09-01T12:01:00Z",
    "updated_at": "2023-09-01T12:01:00Z",
    "notation": "▲7六歩"
  }
]
```

#### 2. 分岐リストの取得

**エンドポイント**: `GET /api/v1/games/:game_id/board_histories/branches`

**パラメータ**:
- `game_id`: ゲームID (必須)

**レスポンス**:
```json
{
  "branches": ["main", "branch_1", "branch_2"]
}
```

#### 3. 指定した手数の局面に移動

**エンドポイント**: `POST /api/v1/games/:game_id/navigate_to/:move_number`

**パラメータ**:
- `game_id`: ゲームID (必須)
- `move_number`: 移動先の手数 (必須)
- `branch`: 分岐名 (任意、デフォルト: "main")

**レスポンス**:
```json
{
  "game_id": 123,
  "board_id": 456,
  "move_number": 3,
  "sfen": "lnsgkgsnl/1r5b1/pp1pppppp/2p6/9/P8/1PPPPPPPP/1B5R1/LNSGKGSNL b - 3"
}
```

#### 4. 分岐切り替え

**エンドポイント**: `POST /api/v1/games/:game_id/switch_branch/:branch_name`

**パラメータ**:
- `game_id`: ゲームID (必須)
- `branch_name`: 分岐名 (必須)

**レスポンス**:
```json
{
  "game_id": 123,
  "branch": "branch_1",
  "current_move_number": 5
}
```

### 実装計画

#### バックエンド実装（Rails）

1. **データベースマイグレーション**
   ```ruby
   # Railsコンテナ内でマイグレーションファイルを生成
   docker-compose exec rails rails generate migration CreateBoardHistories
   
   # マイグレーションファイルを編集
   # db/migrate/YYYYMMDDHHMMSS_create_board_histories.rb
   
   # マイグレーションを実行
   docker-compose exec rails rails db:migrate
   ```

2. **モデル実装**
   - `BoardHistory` モデルの作成
   - 関連するバリデーションの設定
   - `Game` モデルとのアソシエーション設定

3. **コントローラ実装**
   - `BoardHistoriesController` の作成
   - 局面履歴の取得、分岐管理、局面移動の実装
   - 既存の `MovesController` の拡張

4. **ルーティング設定**
   - API エンドポイントのルーティング追加

5. **テスト実装**
   - モデルテスト
   - コントローラテスト
   - 統合テスト

#### フロントエンド実装（Vue.js）

1. **コンポーネント設計**
   - `MoveHistoryPanel.vue` - 手の履歴表示と操作UI
   - 既存の `ShogiBoard.vue` と連携

2. **状態管理**
   - Vuex/Pinia を使用した状態管理
   - 局面と履歴データの同期

3. **UIデザイン**
   - 棋譜リストの表示
   - ナビゲーションコントロール
   - 分岐選択UI

4. **API連携**
   - バックエンドAPIと通信
   - エラーハンドリング

## UI設計

### 移動履歴パネル

![履歴パネルモックアップ](./history_panel_mockup.png)

1. **棋譜リスト**
   - 各手の手数と棋譜表記
   - 現在の手をハイライト表示
   - クリックで任意の手に移動可能

2. **ナビゲーションコントロール**
   - 「最初へ」「一手前へ」「一手先へ」「最後へ」ボタン
   - 現在地の表示

3. **分岐管理**
   - 分岐リストのドロップダウン
   - 分岐名の表示

## 制約と注意点

1. **パフォーマンス**
   - 長い対局の場合、ページネーションの検討
   - クライアント側でのキャッシュ最適化

2. **同期**
   - 対局中の場合、リアルタイムでの更新が必要

3. **エラー処理**
   - 存在しない手数や分岐へのアクセス時の適切なエラー表示

4. **バージョン管理**
   - 将来的な拡張性を考慮した設計

## 追加検討事項

1. **棋譜のエクスポート/インポート**
   - KIF, CSA, SFEN 形式での棋譜のエクスポート機能
   - 外部棋譜ファイルのインポート機能

2. **コメント機能**
   - 各局面にコメントを残せる機能
   - 分岐ごとのコメント管理

3. **局面評価**
   - 各局面での評価値表示
   - エンジン連携

## 実装スケジュール

| フェーズ | 作業内容 | 期間 |
|---------|---------|------|
| 設計 | 詳細設計、API仕様策定 | 1週間 |
| バックエンド実装 | DB設計、API実装、テスト | 2週間 |
| フロントエンド実装 | コンポーネント作成、API連携 | 2週間 |
| 統合テスト | 結合テスト、バグ修正 | 1週間 |
| リリース準備 | 最終確認、デプロイ準備 | 0.5週間 |

**合計期間**: 約6.5週間

## 開発における前提条件

1. **バックエンド**
   - Ruby on Rails 7.0以上
   - PostgreSQL データベース
   - Dockerコンテナ上で動作
   - RSwag APIドキュメンテーション

2. **フロントエンド**
   - Vue.js 3.0以上
   - TypeScript
   - Vite ビルドツール
   - Pinia 状態管理

3. **開発環境**
   - Docker 開発環境
   - GitHubフロー
   - CI/CD パイプライン 