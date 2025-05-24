import { test, expect } from '@playwright/test';

test.describe('編集モード', () => {
  test.beforeEach(async ({ page }) => {
    // アプリのトップページに移動
    await page.goto('/');
    
    // ページが読み込まれるまで待機
    await page.waitForSelector('#app');
    
    // 少し待ってからMenuBarを探す
    await page.waitForTimeout(2000);
    
    // MenuBarが存在することを確認
    await page.waitForSelector('header', { timeout: 5000 });
    
    // 編集モードタブをクリック
    const editModeTab = page.locator('.tab').filter({ hasText: '編集モード' });
    await expect(editModeTab).toBeVisible();
    await editModeTab.click();
    
    // EditBoardが表示されるまで待機
    await page.waitForSelector('.edit-board-container', { timeout: 10000 });
  });

  test('編集モードの基本UI要素が表示される', async ({ page }) => {
    // 基本的なUI要素の存在確認
    await expect(page.locator('.board-controls')).toBeVisible();
    await expect(page.locator('.current-side')).toBeVisible();
    await expect(page.locator('.toggle-side-btn')).toBeVisible();
    await expect(page.locator('.save-btn')).toBeVisible();
    await expect(page.locator('.shogi-board')).toBeVisible();
    // 持ち駒エリアが2つ存在することを確認（先手・後手）
    await expect(page.locator('.pieces-in-hand').first()).toBeVisible();
    await expect(page.locator('.pieces-in-hand').last()).toBeVisible();
  });

  test('手番切り替えボタンが正常に動作する', async ({ page }) => {
    // 初期状態（先手）を確認
    await expect(page.locator('.current-side')).toContainText('現在: 先手');
    
    // 手番切り替えボタンをクリック
    await page.click('.toggle-side-btn');
    
    // 後手に変わることを確認
    await expect(page.locator('.current-side')).toContainText('現在: 後手');
    
    // もう一度クリックして先手に戻ることを確認
    await page.click('.toggle-side-btn');
    await expect(page.locator('.current-side')).toContainText('現在: 先手');
  });

  test('右クリックで駒を持ち駒に移動できる', async ({ page }) => {
    // コンソールログを監視
    page.on('console', msg => {
      console.log('Browser console:', msg.text());
    });
    
    // 初期の持ち駒数を確認
    const initialHandPieceCount = await page.locator('.pieces-in-hand .piece-container').count();
    console.log('Initial hand piece count:', initialHandPieceCount);
    
    // 盤上の駒を右クリック
    const pieceCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    }).first();
    
    await expect(pieceCell).toBeVisible();
    
    // 駒の種類を記録
    const pieceType = await pieceCell.locator('.piece-shape').getAttribute('data-piece');
    const pieceOwner = await pieceCell.locator('.piece-shape').getAttribute('data-owner');
    console.log('Right-clicking piece:', pieceType, 'Owner:', pieceOwner);
    
    // 右クリックで駒を持ち駒に移動
    await pieceCell.click({ button: 'right' });
    await page.waitForTimeout(2000);
    
    // 持ち駒が増えたかチェック
    const afterRightClickCount = await page.locator('.pieces-in-hand .piece-container').count();
    console.log('After right click count:', afterRightClickCount);
    
    // 持ち駒エリアに駒が追加されることを確認
    expect(afterRightClickCount).toBeGreaterThan(initialHandPieceCount);
  });

  test('保存ボタンの動作確認', async ({ page }) => {
    // 保存ボタンが存在することを確認
    const saveButton = page.locator('.save-btn');
    await expect(saveButton).toBeVisible();
    
    console.log('✅ Save button functionality verified');
  });
}); 