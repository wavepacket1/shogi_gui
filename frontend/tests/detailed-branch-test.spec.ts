import { test, expect } from '@playwright/test';

test('詳細分岐機能テスト', async ({ page }) => {
  console.log('=== 詳細分岐機能テスト開始 ===');
  
  // ブラウザコンソールログを監視
  page.on('console', msg => {
    console.log(`🖥️ [${msg.type()}]:`, msg.text());
  });
  
  // ネットワークリクエストを監視
  page.on('request', request => {
    if (request.url().includes('all_branches')) {
      console.log('🌐 API Request:', request.url());
    }
  });
  
  page.on('response', response => {
    if (response.url().includes('all_branches')) {
      console.log('📡 API Response:', response.status(), response.url());
    }
  });
  
  // ページを開く
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(2000);

  console.log('1. ゲーム1876にアクセス...');
  await page.goto('http://localhost:5173?game_id=1876');
  await page.waitForTimeout(5000);

  console.log('2. MoveHistoryPanelの読み込み完了を待機...');
  await page.waitForSelector('.move-history-panel', { timeout: 10000 });
  await page.waitForTimeout(3000);

  console.log('3. 分岐インジケータを詳細検索...');
  
  // すべての可能なセレクタを試す
  const selectors = [
    '.branch-indicator',
    '.branch-toggle-btn',
    '.plus-button',
    '[data-branch-indicator]',
    'text="+"',
    '.move-item:has(.branch-indicator)'
  ];
  
  for (const selector of selectors) {
    const count = await page.locator(selector).count();
    console.log(`セレクタ "${selector}": ${count}個`);
  }

  console.log('4. move-itemを詳細確認...');
  const moveItems = await page.locator('.move-item').count();
  console.log(`move-item数: ${moveItems}`);
  
  for (let i = 0; i < Math.min(moveItems, 5); i++) {
    const itemText = await page.locator('.move-item').nth(i).textContent();
    const hasBranchIndicator = await page.locator('.move-item').nth(i).locator('.branch-indicator').count() > 0;
    console.log(`move-item[${i}]: "${itemText}" - 分岐インジケータ: ${hasBranchIndicator}`);
  }

  console.log('5. JavaScript実行でallBoardHistoriesを確認...');
  await page.evaluate(() => {
    console.log('🎯 ブラウザ内での分岐データ確認開始');
    
    // Vueアプリインスタンスにアクセスを試行
    const app = (window as any).__VUE__;
    if (app) {
      console.log('Vue アプリ発見');
    } else {
      console.log('Vue アプリにアクセスできません');
    }
  });

  await page.waitForTimeout(2000);
  
  console.log('=== 詳細分岐機能テスト完了 ===');
}); 