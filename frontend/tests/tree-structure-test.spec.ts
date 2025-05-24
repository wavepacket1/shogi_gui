import { test, expect } from '@playwright/test';

test('分岐ツリー構造テスト', async ({ page }) => {
  console.log('=== 分岐ツリー構造テスト開始 ===');
  
  // ブラウザコンソールログを監視
  page.on('console', msg => {
    if (msg.type() === 'log' && (msg.text().includes('🌳') || msg.text().includes('🔍'))) {
      console.log('🖥️ ツリー構造ログ:', msg.text());
    }
  });
  
  // ページを開く
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(3000);

  console.log('1. 新規ゲームを作成...');
  // 新規ゲーム作成
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(5000);

  console.log('2. 分岐を作成してツリー構造を構築...');
  
  // ゲームIDを取得
  const gameId = await page.evaluate(() => {
    return window.localStorage.getItem('currentGameId') || '1923';
  });
  console.log(`ゲームID: ${gameId}`);

  // 複数の分岐を作成してツリー構造をテスト
  console.log('3. 第1手（5六歩）を指す...');
  const move1Result = await page.evaluate(async (gameId) => {
    const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/boards/0/move`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        move: {
          from_row: 6,
          from_col: 4,
          to_row: 5,
          to_col: 4
        }
      })
    });
    return await response.json();
  }, gameId);
  console.log('第1手結果:', move1Result);

  console.log('4. 第2手（8四歩）を指す...');
  const move2Result = await page.evaluate(async (gameId) => {
    const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/boards/${window.currentBoardId || move1Result.board_id}/move`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        move: {
          from_row: 2,
          from_col: 7,
          to_row: 3,
          to_col: 7
        }
      })
    });
    return await response.json();
  }, gameId);
  console.log('第2手結果:', move2Result);

  console.log('5. 初期局面に戻って別の第1手（7六歩）を指す...');
  await page.evaluate(async (gameId) => {
    await fetch(`http://localhost:3000/api/v1/games/${gameId}/navigate_to/0`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ branch: 'main' })
    });
  }, gameId);

  const branch1Move = await page.evaluate(async (gameId) => {
    const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/boards/0/move`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        move: {
          from_row: 6,
          from_col: 6,
          to_row: 5,
          to_col: 6
        }
      })
    });
    return await response.json();
  }, gameId);
  console.log('分岐1の第1手結果:', branch1Move);

  console.log('6. 分岐ツリー構造をAPIで取得...');
  const treeStructure = await page.evaluate(async (gameId) => {
    const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/board_histories/branch_tree`);
    return await response.json();
  }, gameId);
  console.log('🌳 分岐ツリー構造:', JSON.stringify(treeStructure, null, 2));

  console.log('7. 手数0での分岐情報をAPIで取得...');
  const branchesAtMove0 = await page.evaluate(async (gameId) => {
    const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/board_histories/branches_at_move/0`);
    return await response.json();
  }, gameId);
  console.log('📊 手数0の分岐情報:', branchesAtMove0);

  console.log('8. 手数1での分岐情報をAPIで取得...');
  const branchesAtMove1 = await page.evaluate(async (gameId) => {
    const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/board_histories/branches_at_move/1`);
    return await response.json();
  }, gameId);
  console.log('📊 手数1の分岐情報:', branchesAtMove1);

  console.log('9. UI上で分岐インジケータを確認...');
  await page.waitForTimeout(3000);
  
  // MoveHistoryPanelが表示されるまで待機
  await page.waitForSelector('.move-history-panel', { timeout: 10000 });

  // 分岐インジケータの数を確認
  const branchIndicators = await page.locator('.branch-indicator').count();
  console.log(`UIでの分岐インジケータ数: ${branchIndicators}`);

  // 成功条件の確認
  expect(treeStructure.total_branches).toBeGreaterThan(1);
  expect(branchesAtMove0.has_branches).toBe(true);
  expect(branchIndicators).toBeGreaterThan(0);

  console.log('=== 分岐ツリー構造テスト完了 ===');
}); 