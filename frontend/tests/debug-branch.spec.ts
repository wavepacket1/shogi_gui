import { test, expect } from '@playwright/test';

test('分岐作成デバッグテスト', async ({ page }) => {
  console.log('=== 分岐作成デバッグテスト開始 ===');
  
  // コンソールログを監視
  page.on('console', msg => {
    if (msg.type() === 'log') {
      console.log('🖥️ ブラウザログ:', msg.text());
    }
  });

  // アプリケーションにアクセス
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(2000);
  
  // 新しいゲームを作成
  const newGameButton = page.locator('button', { hasText: '新しいゲーム' });
  if (await newGameButton.count() > 0) {
    await newGameButton.click();
    await page.waitForTimeout(3000);
  }

  // 検討モードに切り替え
  const studyTab = page.locator('.tab').filter({ hasText: '検討' });
  if (await studyTab.count() > 0) {
    await studyTab.click();
    await page.waitForTimeout(2000);
  }

  // 1手指す (7六歩)
  console.log('1手目: 7六歩を指します');
  await makeMove(page, 6, 6, 5, 6);
  await page.waitForTimeout(2000);

  // 現在の状態をチェック
  const moveItems = page.locator('.move-item');
  const moveCount = await moveItems.count();
  console.log(`現在の手順数: ${moveCount}`);

  // 分岐インジケータの確認
  const branchIndicators = page.locator('.branch-indicator');
  const branchCount = await branchIndicators.count();
  console.log(`分岐インジケータ数: ${branchCount}`);

  console.log('=== 分岐作成デバッグテスト完了 ===');
});

// ヘルパー関数: 駒を移動させる
async function makeMove(page: any, fromRow: number, fromCol: number, toRow: number, toCol: number) {
  try {
    // 移動元のセルをクリック
    const fromCell = page.locator('.shogi-cell').nth(fromRow * 9 + fromCol);
    await fromCell.click();
    await page.waitForTimeout(500);
    
    // 移動先のセルをクリック
    const toCell = page.locator('.shogi-cell').nth(toRow * 9 + toCol);
    await toCell.click();
    await page.waitForTimeout(500);
    
    console.log(`駒移動完了: (${fromRow},${fromCol}) → (${toRow},${toCol})`);
  } catch (error) {
    console.error('駒移動エラー:', error);
  }
} 