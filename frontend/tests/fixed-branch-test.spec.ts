import { test, expect } from '@playwright/test';

test('正しいゲーム1876での分岐テスト', async ({ page }) => {
  console.log('=== 正しいゲーム1876での分岐テスト開始 ===');
  
  // すべてのコンソールとネットワークログを監視
  page.on('console', msg => {
    console.log(`🖥️ [${msg.type()}]:`, msg.text());
  });
  
  page.on('request', request => {
    if (request.url().includes('api/v1/games')) {
      console.log('🌐 API Request:', request.url());
    }
  });
  
  page.on('response', response => {
    if (response.url().includes('api/v1/games')) {
      console.log('📡 API Response:', response.status(), response.url());
    }
  });

  console.log('1. 直接ゲーム1876のページにアクセス...');
  // URLパラメータでゲームIDを明示的に指定
  await page.goto('http://localhost:5173/', { waitUntil: 'networkidle' });
  
  console.log('2. ページロード後、ゲーム1876のデータを手動で設定...');
  // JavaScript実行でゲームIDを明示的に設定
  await page.evaluate(() => {
    console.log('🎯 ゲーム1876を強制設定');
    // ローカルストレージまたはURLパラメータでゲームIDを設定
    localStorage.setItem('currentGameId', '1876');
    
    // URLを更新
    const url = new URL(window.location.href);
    url.searchParams.set('game_id', '1876');
    history.replaceState({}, '', url.toString());
  });

  console.log('3. ページをリロードしてゲーム1876の読み込みを確認...');
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForTimeout(5000);

  console.log('4. MoveHistoryPanelの表示を確認...');
  await page.waitForSelector('.move-history-panel', { timeout: 10000 });
  
  console.log('5. API リクエストでゲーム1876のデータを直接確認...');
  const response = await page.evaluate(async () => {
    try {
      const resp = await fetch('http://localhost:3000/api/v1/games/1876/board_histories/all_branches');
      const data = await resp.json();
      console.log('🔍 直接API呼び出し結果:', {
        status: resp.status,
        dataLength: data.length,
        branches: [...new Set(data.map((h: any) => h.branch))],
        moveNumbers: [...new Set(data.map((h: any) => h.move_number))],
        fullData: data
      });
      return data;
    } catch (error) {
      console.error('API呼び出しエラー:', error);
      return null;
    }
  });

  console.log('6. 結果確認...');
  if (response && response.length > 1) {
    console.log('✅ 分岐データが存在します!');
    
    // 分岐がある手数を特定
    const movesWithBranches = response.reduce((acc: any, history: any) => {
      if (!acc[history.move_number]) {
        acc[history.move_number] = [];
      }
      acc[history.move_number].push(history.branch);
      return acc;
    }, {});
    
    console.log('📊 手数別分岐情報:', movesWithBranches);
    
    for (const [moveNumber, branches] of Object.entries(movesWithBranches)) {
      if ((branches as string[]).length > 1) {
        console.log(`🎯 手数${moveNumber}に${(branches as string[]).length}つの分岐があります: ${(branches as string[]).join(', ')}`);
      }
    }
  } else {
    console.log('❌ 分岐データがありません');
  }

  await page.waitForTimeout(2000);
  console.log('=== 正しいゲーム1876での分岐テスト完了 ===');
}); 