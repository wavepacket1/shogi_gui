import { describe, it, expect, vi, beforeEach } from 'vitest';
import { mount } from '@vue/test-utils';
import GameModeSelector from '@/components/GameModeSelector.vue';
import { GameMode } from '@/store/types';

// モックストア
vi.mock('@/store/mode', () => ({
  useModeStore: vi.fn(() => ({
    currentMode: GameMode.PLAY,
    isLoading: false,
    error: null,
    initializeMode: vi.fn(),
    changeMode: vi.fn().mockResolvedValue({}),
    clearError: vi.fn()
  }))
}));

vi.mock('@/store', () => ({
  useBoardStore: vi.fn(() => ({
    game: { id: 1, status: 'active', board_id: 1 }
  }))
}));

describe('GameModeSelector', () => {
  it('正しくレンダリングされること', () => {
    const wrapper = mount(GameModeSelector);
    expect(wrapper.find('.game-mode-selector').exists()).toBe(true);
    expect(wrapper.findAll('.mode-button').length).toBe(3);
  });

  it('現在のモードのボタンがアクティブになること', () => {
    const wrapper = mount(GameModeSelector);
    const activeButton = wrapper.find('.mode-button.active');
    expect(activeButton.exists()).toBe(true);
    expect(activeButton.text()).toBe('対局モード');
  });

  it('マウント時にinitializeMode()が呼ばれること', () => {
    const modeStore = vi.mocked(vi.importActual('@/store/mode')).useModeStore();
    mount(GameModeSelector);
    expect(modeStore.initializeMode).toHaveBeenCalled();
  });

  it('ボタンクリックでchangeMode()が呼ばれること', async () => {
    const wrapper = mount(GameModeSelector);
    const modeStore = vi.mocked(vi.importActual('@/store/mode')).useModeStore();
    
    await wrapper.findAll('.mode-button')[1].trigger('click');
    expect(modeStore.changeMode).toHaveBeenCalledWith(1, GameMode.EDIT);
  });

  it('すでにアクティブなモードのボタンをクリックしてもchangeMode()が呼ばれないこと', async () => {
    const wrapper = mount(GameModeSelector);
    const modeStore = vi.mocked(vi.importActual('@/store/mode')).useModeStore();
    modeStore.changeMode.mockClear();
    
    await wrapper.findAll('.mode-button')[0].trigger('click');
    expect(modeStore.changeMode).not.toHaveBeenCalled();
  });

  it('ローディング中はボタンが無効化されること', async () => {
    vi.mocked(vi.importActual('@/store/mode')).useModeStore.mockReturnValue({
      currentMode: GameMode.PLAY,
      isLoading: true,
      error: null,
      initializeMode: vi.fn(),
      changeMode: vi.fn(),
      clearError: vi.fn()
    });
    
    const wrapper = mount(GameModeSelector);
    const buttons = wrapper.findAll('.mode-button');
    
    buttons.forEach(button => {
      expect(button.attributes('disabled')).toBeDefined();
    });
  });

  it('エラーが表示されること', async () => {
    vi.mocked(vi.importActual('@/store/mode')).useModeStore.mockReturnValue({
      currentMode: GameMode.PLAY,
      isLoading: false,
      error: 'テストエラー',
      initializeMode: vi.fn(),
      changeMode: vi.fn(),
      clearError: vi.fn()
    });
    
    const wrapper = mount(GameModeSelector);
    const errorMessage = wrapper.find('.error-message');
    
    expect(errorMessage.exists()).toBe(true);
    expect(errorMessage.text()).toBe('テストエラー');
  });

  it('ゲームがない場合はボタンが無効化されること', async () => {
    vi.mocked(vi.importActual('@/store')).useBoardStore.mockReturnValue({
      game: null
    });
    
    const wrapper = mount(GameModeSelector);
    const buttons = wrapper.findAll('.mode-button');
    
    buttons.forEach(button => {
      expect(button.attributes('disabled')).toBeDefined();
    });
  });
}); 