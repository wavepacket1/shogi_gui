import { test, expect } from '@playwright/test';

test('分岐ツリーAPI機能テスト', async ({ page }) => {
  console.log('=== 分岐ツリーAPI機能テスト開始 ===');
  
  console.log('1. 既存のゲーム1876（分岐があることが確認済み）にアクセス...');
  await page.goto('http://localhost:5173?game_id=1876');
  await page.waitForTimeout(5000);

  console.log('2. 分岐ツリー構造をAPIで取得...');
  const treeStructure = await page.evaluate(async () => {
    const response = await fetch('http://localhost:3000/api/v1/games/1876/board_histories/branch_tree');
    return await response.json();
  });
  console.log('🌳 分岐ツリー構造:', JSON.stringify(treeStructure, null, 2));

  console.log('3. 手数0での分岐情報をAPIで取得...');
  const branchesAtMove0 = await page.evaluate(async () => {
    const response = await fetch('http://localhost:3000/api/v1/games/1876/board_histories/branches_at_move/0');
    return await response.json();
  });
  console.log('📊 手数0の分岐情報:', branchesAtMove0);

  console.log('4. 手数1での分岐情報をAPIで取得...');
  const branchesAtMove1 = await page.evaluate(async () => {
    const response = await fetch('http://localhost:3000/api/v1/games/1876/board_histories/branches_at_move/1');
    return await response.json();
  });
  console.log('📊 手数1の分岐情報:', branchesAtMove1);

  console.log('5. UI上で分岐インジケータを確認...');
  await page.waitForSelector('.move-history-panel', { timeout: 10000 });

  // 分岐インジケータの数を確認
  const branchIndicators = await page.locator('.branch-indicator').count();
  console.log(`UIでの分岐インジケータ数: ${branchIndicators}`);

  // 分岐インジケータの詳細を取得
  const indicatorDetails = await page.locator('.branch-indicator').all();
  const details = [];
  for (let i = 0; i < indicatorDetails.length; i++) {
    const indicator = indicatorDetails[i];
    const isVisible = await indicator.isVisible();
    const countText = await indicator.locator('.branch-count').textContent();
    details.push({ index: i, text: countText, visible: isVisible });
  }
  console.log('分岐インジケータの詳細:', details);

  // API結果の検証
  console.log('6. API結果の検証...');
  expect(treeStructure).toBeDefined();
  expect(treeStructure.total_branches).toBeGreaterThan(1);
  console.log(`✅ 分岐総数: ${treeStructure.total_branches}`);

  expect(branchesAtMove0).toBeDefined();
  expect(branchesAtMove0.branch_count).toBeGreaterThan(1);
  console.log(`✅ 手数0の分岐数: ${branchesAtMove0.branch_count}`);

  expect(branchesAtMove1).toBeDefined();
  expect(branchesAtMove1.branch_count).toBeGreaterThan(1);
  console.log(`✅ 手数1の分岐数: ${branchesAtMove1.branch_count}`);

  // UI検証
  expect(branchIndicators).toBeGreaterThan(0);
  console.log(`✅ UI分岐インジケータ数: ${branchIndicators}`);

  console.log('=== 分岐ツリーAPI機能テスト完了 ===');
}); 