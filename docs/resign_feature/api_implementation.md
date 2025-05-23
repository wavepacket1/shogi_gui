# 投了API実装手順

## 1. Swagger定義の作成
```yaml
# swagger/v1/swagger.yaml
paths:
  /api/v1/games/{id}/resign:
    post:
      summary: 対局の投了
      tags:
        - Games
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: integer
      responses:
        200:
          description: 投了成功
          content:
            application/json:
              schema:
                type: object
                properties:
                  status:
                    type: string
                    example: success
                  game_status:
                    type: string
                    example: resigned
                  winner:
                    type: string
                    enum: [black, white]
                  end_reason:
                    type: string
                    example: resign
                  ended_at:
                    type: string
                    format: date-time
        403:
          description: 権限エラー
        422:
          description: 投了不可能な状態
```

## 2. バックエンドAPI実装
1. コントローラーの実装
2. モデルの実装
3. テストの作成
4. Swagger定義の生成
```bash
rake rswag:specs:swaggerize
```

## 3. フロントエンドAPIクライアント生成
```bash
npx swagger-typescript-api generate \
  --path ../backend/swagger/v1/openapi.yaml \
  --output ./src/services/api \
  --name "api.ts"
```

## 4. 型定義の確認
生成されたAPIクライアントの型定義を確認し、必要に応じて拡張：
```typescript
// frontend/src/types/game.ts
export interface ResignResponse {
  status: 'success' | 'error';
  game_status: 'active' | 'resigned' | 'checkmate';
  winner: 'black' | 'white';
  end_reason: 'resign' | 'checkmate';
  ended_at: string;
}
```

## 5. APIテスト
```ruby
# spec/requests/api/v1/games_spec.rb
RSpec.describe 'Games API' do
  describe 'POST /api/v1/games/:id/resign' do
    # テストケース
  end
end
```

## 6. 動作確認手順
1. Swagger定義の生成確認
2. APIクライアントの生成確認
3. エンドポイントの動作確認
4. レスポンス形式の確認

## 注意事項
- APIの変更時は必ずSwagger定義を更新
- Swagger定義更新後は必ずクライアントを再生成
- RESTfulの原則に従ったエンドポイント設計
- レスポンスは一貫した形式で返却 