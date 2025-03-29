# 将棋GUI 手の履歴機能 - 概要と基本設計

## 1. 機能概要

将棋GUIアプリケーションにおける「手の履歴機能」は、対局中の各手の履歴を記録・表示し、過去の局面に戻ったり異なる手を検討したりする機能を提供します。この機能により、以下のことが可能になります：

- 指された手の履歴を時系列順に閲覧する
- 任意の過去の局面に移動する
- 過去の局面から異なる手を試す（分岐の作成）
- 複数の分岐間を切り替える
- 棋譜として手を日本語表記で表示する

## 2. 主要コンポーネント

本機能は以下の主要コンポーネントから構成されます：

1. **データモデル**: 局面履歴を保存・管理するためのデータベース構造
2. **バックエンドAPI**: 履歴の取得、局面の移動、分岐の管理などの機能を提供するREST API
3. **フロントエンドコンポーネント**: 棋譜履歴を表示し、操作するためのユーザーインターフェース

## 3. データベース設計

### 3.1 ER図

```
+----------------+       +----------------+       +----------------+
|     Game       |       |     Board      |       | BoardHistory   |
+----------------+       +----------------+       +----------------+
| id             |<----->| id             |       | id             |
| status         |       | sfen           |       | game_id        |
| created_at     |       | game_id        |       | sfen           |
| updated_at     |       | created_at     |       | move_number    |
+----------------+       | updated_at     |       | branch         |
                         +----------------+       | created_at     |
                                                 | updated_at     |
                                                 +----------------+
```

### 3.2 テーブル定義

#### BoardHistoriesテーブル

| フィールド名 | 型         | 制約                  | 説明                    |
|--------------|------------|----------------------|-------------------------|
| id           | integer    | primary key          | 主キー                  |
| game_id      | integer    | foreign key, not null| ゲームへの参照          |
| sfen         | string     | not null             | 局面のSFEN形式表現      |
| move_number  | integer    | not null             | 手数                    |
| branch       | string     | default: 'main'      | 分岐名                  |
| created_at   | datetime   | not null             | 作成日時                |
| updated_at   | datetime   | not null             | 更新日時                |

**インデックス**:
- `[game_id, move_number, branch]` (一意性制約)

### 3.3 リレーションシップ

- **Game**: `has_many :board_histories, dependent: :destroy`
- **BoardHistory**: `belongs_to :game`

## 4. クラス設計

### 4.1 クラス図

```
+----------------+       +----------------+       +----------------+
|     Game       |       |     Board      |       | BoardHistory   |
+----------------+       +----------------+       +----------------+
| +board         |       | +sfen          |       | +sfen          |
| +board_histories|      | +game          |       | +move_number   |
|                |       |                |       | +branch        |
+----------------+       +----------------+       | +game          |
| +create()      |       | +update()      |       |                |
|                |       |                |       +----------------+
|                |       |                |       | +previous_board_history() |
+----------------+       +----------------+       | +next_board_history()     |
                                                 | +first_board_history()    |
                                                 | +last_board_history()     |
                                                 | +get_move_info()          |
                                                 | +to_kifu_notation()       |
                                                 +----------------+
```

### 4.2 BoardHistoryモデル

BoardHistoryモデルは以下のメソッドを提供します：

- **previous_board_history**: 前の局面の履歴を取得
- **next_board_history**: 次の局面の履歴を取得
- **first_board_history**: 同じ分岐の最初の局面を取得
- **last_board_history**: 同じ分岐の最後の局面を取得
- **get_move_info**: 前の局面との差分から手の情報を取得
- **to_kifu_notation**: 日本語の棋譜表記を生成

### 4.3 コントローラ

#### BoardHistoriesController

局面履歴に関連する操作を処理するコントローラ：

- **index**: 指定したゲームの局面履歴を取得
- **branches**: 指定したゲームの分岐リストを取得
- **navigate_to**: 指定した手数の局面に移動
- **switch_branch**: 指定した分岐に切り替え

#### MovesController（拡張）

既存のMovesコントローラを拡張して局面履歴を保存：

- **move**: 駒の移動処理と同時に局面履歴を保存

## 5. フロントエンド設計

### 5.1 コンポーネント構成

```
+----------------+       +----------------+
|   ShogiBoard   |       | MoveHistoryPanel |
+----------------+       +----------------+
| -board         |<----->| -boardHistories|
| -game          |       | -currentMove   |
|                |       | -branches      |
+----------------+       +----------------+
| +handleMove()  |       | +fetchHistories() |
|                |       | +navigateToMove() |
+----------------+       | +changeBranch()   |
                         +----------------+
```

### 5.2 MoveHistoryPanelコンポーネント

手の履歴を表示し操作するためのUIコンポーネント：

- 履歴リスト表示
- 現在の手のハイライト
- ナビゲーションボタン（最初へ/前へ/次へ/最後へ）
- 分岐セレクター

### 5.3 ユーザーインターフェースレイアウト

```
+------------------------------------------+
|                 Header                   |
+------------------------------------------+
|                               |          |
|                               |  Move    |
|                               |  History |
|        Shogi Board            |  Panel   |
|                               |          |
|                               |          |
|                               |          |
+------------------------------------------+
```

## 6. 実装方針

### 6.1 バックエンド

1. `BoardHistory`モデルとマイグレーションの作成
2. モデル間のリレーションシップの設定
3. `BoardHistoriesController`の実装
4. `MovesController`の拡張
5. ルーティングの設定
6. Rswagによるapi仕様の作成・テスト

### 6.2 フロントエンド

1. OpenAPI Generator を使用して TypeScript API クライアントを生成
2. Vuex/Pinia ストアの拡張
3. `MoveHistoryPanel.vue`コンポーネントの実装
4. 既存の`ShogiBoard.vue`コンポーネントとの統合
5. スタイリングとレスポンシブデザインの適用

## 7. 技術スタック

### 7.1 バックエンド

- **言語**: Ruby
- **フレームワーク**: Ruby on Rails
- **API仕様**: OpenAPI / Rswag
- **データベース**: PostgreSQL / MySQL

### 7.2 フロントエンド

- **言語**: TypeScript
- **フレームワーク**: Vue.js 3
- **状態管理**: Vuex / Pinia
- **APIクライアント**: OpenAPI Generator
- **UIフレームワーク**: カスタムスタイリング

## 8. 考慮事項と制約

### 8.1 パフォーマンス

- 長い対局（数百手）でも履歴パネルがスムーズに動作するよう、ページネーションを考慮する
- 分岐が多い場合のデータ管理と表示の最適化

### 8.2 データ整合性

- 分岐の作成時に適切な命名規則を適用し、競合を防止する
- 手の履歴データの整合性を保証するためのバリデーション

### 8.3 セキュリティ

- 認証・認可による適切なアクセス制御
- 入力値の検証とサニタイズ

### 8.4 アクセシビリティ

- キーボード操作のサポート
- スクリーンリーダー対応のための適切なARIAラベル

## 9. 将来の拡張性

本設計は以下の将来的な拡張を考慮しています：

1. 局面へのコメント追加機能
2. AIによる指し手評価の表示
3. 棋譜のエクスポート/インポート機能
4. 複数のゲーム間での局面の共有
5. 分岐の視覚的表現（ツリービュー） 