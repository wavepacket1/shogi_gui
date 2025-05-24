import { test, expect } from '@playwright/test';

test('基本的なUI表示のテスト', async ({ page }) => {
  // フロントエンドのページを開く
  await page.goto('http://localhost:5173/');
  
  // ページのタイトルを確認
  await expect(page).toHaveTitle(/Vite \+ Vue \+ TS/);

  // メニューバーのタブボタンの存在を確認
  const playModeTab = page.locator('.tab:has-text("対局モード")');
  await expect(playModeTab).toBeVisible();
  
  const editModeTab = page.locator('.tab:has-text("編集モード")');
  await expect(editModeTab).toBeVisible();
  
  const studyModeTab = page.locator('.tab:has-text("検討モード")');
  await expect(studyModeTab).toBeVisible();
  
  // タブがクリック可能であることを検証
  await expect(playModeTab).toBeEnabled();
  await expect(editModeTab).toBeEnabled();
  await expect(studyModeTab).toBeEnabled();
  
  // 対局モードタブをクリックする動作のテスト
  console.log('対局モードタブをクリックします...');
  await playModeTab.click();
  
  // クリック後、対局モードタブがアクティブになることを確認
  await expect(playModeTab).toHaveClass(/active/);
  
  // クリック後のスクリーンショットを撮影
  await page.screenshot({ path: 'frontend/tests/screenshots/basic-ui-after-click.png', fullPage: true });
}); 