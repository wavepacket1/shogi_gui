# ディレクトリ構成

```
shogi_gui/
├── frontend/                # フロントエンド（Vue.js）
│   ├── src/
│   │   ├── assets/        # 静的ファイル（画像、スタイル等）
│   │   ├── components/    # Vueコンポーネント
│   │   ├── services/      # APIサービス、ユーティリティ
│   │   │   └── api/      # APIクライアント（swagger-typescript-api生成）
│   │   ├── store/        # Piniaストア
│   │   ├── types/        # TypeScript型定義
│   │   ├── views/        # ページコンポーネント
│   │   ├── App.vue       # ルートコンポーネント
│   │   └── main.ts       # エントリーポイント
│   ├── public/           # 公開静的ファイル
│   ├── tests/            # フロントエンドテスト
│   ├── package.json      # 依存関係
│   └── vite.config.ts    # Vite設定
│
├── backend/               # バックエンド（Ruby on Rails）
│   ├── app/
│   │   ├── controllers/  # コントローラー
│   │   ├── models/      # モデル
│   │   ├── services/    # サービス
│   │   └── views/       # ビュー
│   ├── config/          # 設定ファイル
│   ├── db/              # データベース関連
│   │   ├── migrations/  # マイグレーションファイル
│   │   └── seeds/      # シードデータ
│   ├── spec/            # バックエンドテスト
│   ├── swagger/         # Swagger定義
│   │   └── v1/         # APIバージョン1
│   └── Gemfile         # Ruby依存関係
│
├── .cursor/             # Cursor IDE設定
│   └── rules/          # プロジェクトルール
│
├── docker/              # Docker関連ファイル
│   ├── frontend/       # フロントエンドDocker設定
│   └── backend/        # バックエンドDocker設定
│
├── docs/               # プロジェクトドキュメント
├── .gitignore         # Git除外設定
├── docker-compose.yml # Docker Compose設定
└── README.md          # プロジェクト説明
```

## ディレクトリ説明

### フロントエンド（frontend/）
- `src/`: ソースコードのメインディレクトリ
  - `components/`: 再利用可能なVueコンポーネント
  - `services/`: APIクライアントやユーティリティ関数
  - `store/`: Piniaによる状態管理
  - `views/`: ページレベルのコンポーネント
  - `types/`: TypeScript型定義ファイル

### バックエンド（backend/）
- `app/`: アプリケーションのメインコード
  - `controllers/`: APIエンドポイントのコントローラー
  - `models/`: データモデルとビジネスロジック
  - `services/`: 複雑なビジネスロジック
- `swagger/`: API仕様定義
  - `v1/`: APIバージョン1の定義

### 設定ファイル
- `.cursor/rules/`: プロジェクトルールとガイドライン
- `docker/`: Docker環境の設定ファイル
- `docs/`: プロジェクトドキュメント

## 命名規則

### ファイル名
- コンポーネント: PascalCase（例：`MoveHistoryPanel.vue`）
- サービス: camelCase（例：`apiService.ts`）
- テスト: `*.test.ts`または`*_spec.rb`
- 設定ファイル: ケバブケース（例：`vite.config.ts`）

### ディレクトリ名
- ケバブケース（例：`move-history/`）
- 小文字（例：`components/`）

## 注意事項
- 各ディレクトリの役割を明確に保つ
- 不要なファイルは適切に削除する
- 新しい機能追加時は適切なディレクトリに配置する
- テストファイルは対象のファイルと同じディレクトリに配置する 