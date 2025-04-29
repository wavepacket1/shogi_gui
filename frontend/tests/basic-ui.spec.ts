import { test, expect } from '@playwright/test';

test('基本的なUI表示のテスト', async ({ page }) => {
  // フロントエンドのページを開く
  await page.goto('http://localhost:5173/');
  
  // ページのタイトルを確認
  await expect(page).toHaveTitle(/Vite \+ Vue \+ TS/);

  // 「対局開始」ボタンの存在を確認
  const startButton = page.locator('button:has-text("対局開始")');
  await expect(startButton).toBeVisible();
  
  // 「入玉宣言」ボタンの存在を確認
  const nyugyokuButton = page.locator('button:has-text("入玉宣言")');
  await expect(nyugyokuButton).toBeVisible();
  
  // ボタンがクリック可能であることを検証
  await expect(startButton).toBeEnabled();
  
  // 対局開始ボタンをクリックする動作のテスト
  // 実際の動作はアプリケーションによって異なるため、必要に応じて調整
  console.log('対局開始ボタンをクリックします...');
  await startButton.click();
  
  // クリック後のスクリーンショットを撮影
  await page.screenshot({ path: 'after-click.png', fullPage: true });
}); 