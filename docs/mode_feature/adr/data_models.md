# データ構造 (モード切替機能)

このファイルでは、フロントエンドおよびAPIで利用する型定義をまとめています。

## GameMode / GameModeUpdate

```typescript
export enum GameMode {
  PLAY = 'play',
  EDIT = 'edit',
  STUDY = 'study',
}

export interface GameModeUpdate {
  mode: GameMode;
}
```

## Position

```typescript
export interface Position {
  id: number;
  game_id: number;
  sfen: string;
  active_player: 'black' | 'white';
  mode: GameMode;
  metadata: {
    created_at: string;
    updated_at: string;
  };
}
``` 