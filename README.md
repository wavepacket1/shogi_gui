## 将棋GUI
- docker compose upで起動する
- 対局の開始から詰みまでルール通りに動く
## 構成
スキーマ駆動でやっている
- front
  - vue
  - api
    - typescript  
- backend
  - rails apiモード     

## クラスの依存関係
![バックエンドのクラス図](backend/doc/class_diagram.png)

### 図の説明
- 実線矢印（⟶）：継承関係
- 点線矢印（- ->）：Concernsの関係
- 四角形：クラス
- 六角形：Concerns