import { test, expect } from '@playwright/test';

test('分岐ツリー表示機能テスト', async ({ page }) => {
  console.log('=== 分岐ツリー表示機能テスト開始 ===');
  
  console.log('1. 分岐が存在するゲーム1876にstudyモードでアクセス...');
  await page.goto('http://localhost:5173?game_id=1876&mode=study');
  await page.waitForTimeout(5000);

  console.log('2. MoveHistoryPanelが表示されるまで待機...');
  await page.waitForSelector('.move-history-panel', { timeout: 10000 });

  console.log('3. BranchManagerが表示されることを確認...');
  await page.waitForSelector('.branch-manager', { timeout: 10000 });
  
  const branchManager = page.locator('.branch-manager');
  await expect(branchManager).toBeVisible();
  console.log('BranchManagerが正常に表示されました');

  console.log('4. ツリー表示ボタンの存在確認...');
  const treeButton = page.locator('.tree-view-btn');
  await expect(treeButton).toBeVisible({ timeout: 5000 });
  
  const buttonText = await treeButton.textContent();
  console.log(`ツリー表示ボタンのテキスト: ${buttonText}`);
  expect(buttonText).toContain('ツリー表示');

  console.log('5. ツリー表示ボタンをクリック...');
  await treeButton.click();
  await page.waitForTimeout(3000);

  console.log('6. ツリービューアが表示されることを確認...');
  await page.waitForSelector('.branch-tree-viewer', { timeout: 10000 });
  
  const treeViewer = page.locator('.branch-tree-viewer');
  await expect(treeViewer).toBeVisible();

  console.log('7. ツリーヘッダーの確認...');
  const header = page.locator('.tree-header h4');
  await expect(header).toHaveText('分岐ツリー構造');

  console.log('8. ローディング状態から内容表示への変化を確認...');
  // ローディング状態の待機
  const loading = page.locator('.loading');
  if (await loading.isVisible()) {
    console.log('ローディング表示確認済み');
    // ローディングが消えるまで待機
    await page.waitForSelector('.tree-container', { timeout: 10000 });
    console.log('ツリーコンテナが表示されました');
  } else {
    console.log('ローディング表示をスキップ、直接コンテナを確認');
    await page.waitForSelector('.tree-container', { timeout: 10000 });
  }

  console.log('9. ツリー統計の確認...');
  const treeStats = page.locator('.tree-stats .stat-item');
  await expect(treeStats).toBeVisible();
  
  const statsText = await treeStats.textContent();
  console.log(`ツリー統計: ${statsText}`);
  expect(statsText).toContain('総分岐数');

  console.log('10. ツリー可視化エリアの確認...');
  const treeVisualization = page.locator('.tree-visualization');
  await expect(treeVisualization).toBeVisible();

  console.log('11. 分岐ノードの確認...');
  const branchNodes = page.locator('.branch-node');
  const nodeCount = await branchNodes.count();
  console.log(`分岐ノード数: ${nodeCount}`);
  expect(nodeCount).toBeGreaterThan(0);

  console.log('12. 指し手表示ノードの確認...');  const moveNodes = page.locator('.move-number');  if (await moveNodes.count() > 0) {    console.log('指し手表示が正常に動作しています');    const firstMoveText = await moveNodes.first().textContent();    console.log(`最初の指し手表示: ${firstMoveText}`);  }    const mainNode = page.locator('.node-item.main');  await expect(mainNode).toBeVisible();

  console.log('13. 分岐詳細情報の確認...');
  const branchDetails = page.locator('.branch-details');
  await expect(branchDetails).toBeVisible();

  console.log('14. 分岐ノードクリックでの詳細更新テスト...');
  const firstNode = branchNodes.first();
  await firstNode.click();
  await page.waitForTimeout(1000);
  
  // 詳細情報が更新されることを確認
  const detailItems = page.locator('.detail-item');
  const detailCount = await detailItems.count();
  console.log(`詳細項目数: ${detailCount}`);
  expect(detailCount).toBeGreaterThan(0);

  console.log('15. ツリービューアの閉じるボタンテスト...');
  const closeButton = page.locator('.tree-header .close-btn');
  await expect(closeButton).toBeVisible();
  
  await closeButton.click();
  await page.waitForTimeout(1000);

  console.log('16. ツリービューアが閉じられることを確認...');
  await expect(treeViewer).toBeHidden();

  console.log('=== 分岐ツリー表示機能テスト完了 ===');
}); 