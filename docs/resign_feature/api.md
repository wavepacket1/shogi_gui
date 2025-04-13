# APIエンドポイント仕様

## 1. エンドポイント定義
- パス: `POST /api/v1/games/:id/resign`
- 認証: 必須
- 権限: 対局参加者のみ

## 2. リクエスト/レスポンス
### リクエスト
```json
{
  "game_id": "number (required)"
}
```

### レスポンス
```json
{
  "status": "success",
  "message": "投了が完了しました",
  "game_status": "resigned",
  "winner": "black|white",
  "end_reason": "resign",
  "ended_at": "ISO8601 datetime"
}
```

## 3. 型定義
```typescript
// frontend/src/types/game.ts
export interface GameStatus {
  status: 'active' | 'resigned' | 'checkmate';
  winner: 'black' | 'white' | null;
  endReason: 'resign' | 'checkmate' | null;
  endedAt: string | null;
}

export interface ResignResponse {
  // ... (以下、元の型定義と同じ)
}
``` 