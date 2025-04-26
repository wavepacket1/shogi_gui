# 仕様⇔設計 対応表

以下に `system_spec.md` のセクションと、それを実現する `adr` 配下の設計書を対応表としてまとめます。

| 仕様書箇所             | 対応設計書                           | 備考                                                   |
|------------------------|--------------------------------------|--------------------------------------------------------|
| 1. 概要                | implementation_plan_design.md         | 機能の全体像、開発フェーズ、マイルストーンを定義     |
| 2.1 対局モード         | api_design.md<br>state_diagram_design.puml | 対局APIエンドポイント、状態遷移図（Playステート） |
|                        | database_design.md<br>frontend_design.md | モード切替用DBカラム、対局画面UI（将棋盤・投了など） |
| 2.2 編集モード         | api_design.md<br>state_diagram_design.puml | 局面保存・読み込みAPI、状態遷移図（Editステート） |
|                        | database_design.md<br>frontend_design.md | 編集用DBカラム、編集UI（EditModePanelなど）        |
|                        | state_preservation_design.md         | 編集前局面の保存・復元ロジック                         |
| 2.3 検討モード         | api_design.md<br>state_diagram_design.puml | 棋譜コメント・分岐API、状態遷移図（Studyステート） |
|                        | database_design.md<br>frontend_design.md | 分岐用履歴DB、検討UI（MoveHistoryPanelなど）       |
|                        | state_preservation_design.md         | 検討セッションの状態保存・復元ロジック                 |
| 3. UI仕様              | frontend_design.md                   | モード切替タブ、各モード個別UI要素                     |
| 5. 状態遷移            | state_diagram_design.puml            | 全モード間の遷移ルールを可視化                        |
| 6. エラー処理          | api_design.md<br>frontend_design.md  | バリデーション・エラー定義（API及びUIレイヤー）     |
| 7. 注意事項            | implementation_plan_design.md         | UI/UX変更禁止、技術スタック制約などのガイドライン     |

> ※ 各設計書の詳細は該当ファイル内のドキュメントをご参照ください。 