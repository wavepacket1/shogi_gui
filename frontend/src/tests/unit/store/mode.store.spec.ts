import { describe, it, expect, vi, beforeEach } from 'vitest';
import { setActivePinia, createPinia } from 'pinia';
import { useModeStore } from '@/store/mode';
import { useBoardStore } from '@/store';
import { GameMode } from '@/store/types';

// モック
vi.mock('@/services/api/api', () => {
  return {
    Api: vi.fn().mockImplementation(() => ({
      api: {
        v1GamesModeCreate: vi.fn().mockResolvedValue({
          data: { game_id: 1, mode: 'study', status: 'active' }
        })
      }
    }))
  };
});

vi.mock('@/store', () => {
  return {
    useBoardStore: vi.fn().mockReturnValue({
      game: { id: 1, mode: 'play', status: 'active', board_id: 1 },
      fetchBoard: vi.fn().mockResolvedValue({})
    })
  };
});

describe('ModeStore', () => {
  beforeEach(() => {
    // テスト用のPiniaを作成
    setActivePinia(createPinia());
  });

  it('初期状態が正しく設定されていること', () => {
    const modeStore = useModeStore();
    expect(modeStore.currentMode).toBe(GameMode.PLAY);
    expect(modeStore.isLoading).toBe(false);
    expect(modeStore.error).toBeNull();
  });

  it('initializeMode()がgameModeパラメータで正しく初期化できること', () => {
    const modeStore = useModeStore();
    modeStore.initializeMode(GameMode.STUDY);
    expect(modeStore.currentMode).toBe(GameMode.STUDY);
  });

  it('initializeMode()がgame.modeから正しく初期化できること', () => {
    const modeStore = useModeStore();
    modeStore.initializeMode();
    expect(modeStore.currentMode).toBe(GameMode.PLAY); // モックからの値
  });

  it('clearError()がエラーをクリアできること', () => {
    const modeStore = useModeStore();
    modeStore.error = 'テストエラー';
    modeStore.clearError();
    expect(modeStore.error).toBeNull();
  });

  it('changeMode()が正しくモードを変更できること', async () => {
    const modeStore = useModeStore();
    const boardStore = useBoardStore();
    
    await modeStore.changeMode(1, GameMode.STUDY);
    
    expect(modeStore.currentMode).toBe(GameMode.STUDY);
    expect(modeStore.isLoading).toBe(false);
    expect(modeStore.error).toBeNull();
    expect(boardStore.fetchBoard).toHaveBeenCalled();
  });

  it('changeMode()でエラーが発生した場合正しく処理されること', async () => {
    const modeStore = useModeStore();
    const mockApi = await import('@/services/api/api');
    
    // モックを上書きしてエラーを発生させる
    vi.spyOn(mockApi.Api.prototype.api, 'v1GamesModeCreate').mockRejectedValueOnce(new Error('API Error'));
    
    try {
      await modeStore.changeMode(1, GameMode.EDIT);
    } catch (e) {
      // エラーはthrowされるので、ここでキャッチする
    }
    
    expect(modeStore.isLoading).toBe(false);
    expect(modeStore.error).toBe('モードの変更に失敗しました');
  });

  it('gameIdが未指定の場合エラーになること', async () => {
    const modeStore = useModeStore();
    
    await modeStore.changeMode(0, GameMode.EDIT);
    
    expect(modeStore.error).toBe('ゲームIDが指定されていません');
  });
}); 