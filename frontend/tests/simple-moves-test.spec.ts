import { test, expect } from '@playwright/test';

test('MovesController動作確認テスト', async ({ page }) => {
  console.log('=== MovesController動作確認テスト開始 ===');
  
  // ページを開く
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(2000);

  console.log('1. ゲームを作成...');
  // 新しいゲームボタンを探してクリック
  try {
    await page.locator('button').filter({ hasText: '新しいゲーム' }).click();
    await page.waitForTimeout(3000);
  } catch (error) {
    console.log('新しいゲームボタンが見つからないため、手動で作成...');
  }

  console.log('2. 盤面が表示されるまで待機...');
  await page.waitForSelector('.shogi-board', { timeout: 10000 });
  
  console.log('3. 駒を手動でクリックして移動...');
  
  // 先手の歩（7六歩）を移動
  try {
    // 7六の駒をクリックして選択
    const piece76 = page.locator('.shogi-cell').nth(60); // 概算位置
    await piece76.click();
    await page.waitForTimeout(1000);
    
    // 5六に移動
    const square56 = page.locator('.shogi-cell').nth(42); // 概算位置
    await square56.click();
    await page.waitForTimeout(3000);
    
    console.log('✅ 駒移動完了');
  } catch (error) {
    console.log('❌ 駒移動エラー:', error);
  }
  
  console.log('=== テスト完了（バックエンドログを確認してください） ===');
}); 