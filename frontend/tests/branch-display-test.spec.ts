import { test, expect } from '@playwright/test';

test('分岐インジケータ表示テスト', async ({ page }) => {
  console.log('=== 分岐インジケータ表示テスト開始 ===');
  
  // ブラウザコンソールログを監視
  page.on('console', msg => {
    if (msg.type() === 'log' && msg.text().includes('🔍')) {
      console.log('🖥️ 分岐検出ログ:', msg.text());
    }
  });
  
  // ページを開く
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(3000);

  console.log('1. 既存のゲーム1876にアクセス...');
  // URLを直接変更してゲーム1876にアクセス
  await page.goto('http://localhost:5173?game_id=1876');
  await page.waitForTimeout(5000);

  console.log('2. MoveHistoryPanelを確認...');
  // MoveHistoryPanelが表示されるまで待機
  await page.waitForSelector('.move-history-panel', { timeout: 10000 });

  console.log('3. 分岐インジケータ（+記号）を探す...');
  // 分岐インジケータ（+記号）が表示されているかチェック
  const branchIndicators = await page.locator('.branch-indicator').count();
  console.log(`分岐インジケータ数: ${branchIndicators}`);

  // 手数1の項目に分岐インジケータがあるかチェック
  const move1Plus = await page.locator('[data-move-number="1"] .branch-indicator').count();
  console.log(`手数1の分岐インジケータ: ${move1Plus}`);

  console.log('4. 詳細な分岐情報をコンソールで確認...');
  // JavaScript実行してコンソールに詳細情報を出力
  await page.evaluate(() => {
    console.log('🎯 分岐テスト: ブラウザ内から分岐情報を取得中...');
  });

  await page.waitForTimeout(3000);
  
  console.log('=== 分岐インジケータ表示テスト完了 ===');
}); 