# 仕様⇔設計 対応表

以下に `system_spec.md` のセクションと、それを実現する `adr` 配下の設計書を対応表としてまとめます。

| 仕様書箇所             | 対応設計書                           | 備考                                                   |
|------------------------|--------------------------------------|--------------------------------------------------------|
| 1. 概要                | implementation_plan_design.md         | 機能の全体像、開発フェーズ、マイルストーンを定義     |
| 2.1 対局モード         | api_design.md<br>database_design.md<br>frontend_design.md | 対局API、DBスキーマ、対局画面UI（将棋盤・投了等） |
| 2.2 編集モード         | api_design.md<br>database_design.md<br>frontend_design.md | 編集API、DBスキーマ、編集画面UI（タブ・手番変更等）|
| 2.3 検討モード         | api_design.md<br>database_design.md<br>frontend_design.md<br>er_design.puml<br>data_models.md | 棋譜コメントAPI、DBスキーマ、検討画面UI、ER図、データモデル定義|
| 3. UI仕様              | frontend_design.md                   | モード切替タブ、各モード個別UI要素                     |
| 6. エラー処理          | api_design.md<br>frontend_design.md  | バリデーション・エラー定義（API及びUIレイヤー）     |
| 7. 注意事項            | implementation_plan_design.md         | UI/UX変更禁止、技術スタック制約などのガイドライン     |

> ※ 各設計書の詳細は該当ファイル内のドキュメントをご参照ください。 