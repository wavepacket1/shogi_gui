import { test, expect } from '@playwright/test';

test('ブラウザでゲーム1876の分岐確認', async ({ page }) => {
  console.log('=== ブラウザでゲーム1876の分岐確認開始 ===');
  
  page.on('console', msg => {
    if (msg.text().includes('🔍') || msg.text().includes('分岐') || msg.text().includes('game')) {
      console.log(`🖥️ [${msg.type()}]:`, msg.text());
    }
  });
  
  // 最初にAPIでゲーム1876の存在を確認
  console.log('1. ゲーム1876の存在確認...');
  const apiCheck = await page.request.get('http://localhost:3000/api/v1/games/1876');
  console.log(`ゲーム1876のAPI状態: ${apiCheck.status()}`);
  
  if (apiCheck.status() === 404) {
    console.log('❌ ゲーム1876が存在しません。テストを終了します。');
    return;
  }

  // ゲーム1876の分岐データを事前確認
  console.log('2. ゲーム1876の分岐データを事前確認...');
  const branchData = await page.request.get('http://localhost:3000/api/v1/games/1876/board_histories/all_branches');
  const branches = await branchData.json();
  console.log(`分岐データ数: ${branches.length}`);
  
  const movesWithBranches = branches.reduce((acc: any, history: any) => {
    if (!acc[history.move_number]) acc[history.move_number] = [];
    acc[history.move_number].push(history.branch);
    return acc;
  }, {});
  
  console.log('📊 手数別分岐:', movesWithBranches);

  // URLに直接ゲームIDを含めてアクセス
  console.log('3. ゲーム1876に直接アクセス...');
  await page.goto('http://localhost:5173/#game=1876', { waitUntil: 'networkidle' });
  await page.waitForTimeout(5000);

  console.log('4. 別の方法でゲーム1876にアクセス（URLパラメータ）...');
  await page.goto('http://localhost:5173/?gameId=1876', { waitUntil: 'networkidle' });
  await page.waitForTimeout(5000);

  console.log('5. 手動でゲーム状態を設定...');
  // Vueアプリの状態を直接操作
  await page.evaluate(() => {
    // ゲームIDを強制設定
    console.log('🎯 手動でゲーム1876を設定中...');
    
    // 可能なグローバル変数やストアにアクセスを試行
    if ((window as any).app?.$store) {
      console.log('Vuex/Pinia ストア発見');
    }
    
    // 強制的にゲームデータをロード
    fetch('http://localhost:3000/api/v1/games/1876')
      .then(response => response.json())
      .then(game => {
        console.log('🎮 ゲーム1876データ取得:', game);
      })
      .catch(error => {
        console.error('ゲーム取得エラー:', error);
      });
  });

  await page.waitForTimeout(3000);

  console.log('6. MoveHistoryPanelの確認...');
  await page.waitForSelector('.move-history-panel', { timeout: 10000 });
  
  // 手順項目数を確認
  const moveItems = await page.locator('.move-item').count();
  console.log(`現在の手順項目数: ${moveItems}`);
  
  // 各手順をチェック
  for (let i = 0; i < Math.min(moveItems, 3); i++) {
    const itemText = await page.locator('.move-item').nth(i).textContent();
    console.log(`手順[${i}]: "${itemText}"`);
  }

  console.log('7. 分岐インジケータの存在確認...');
  const branchIndicators = await page.locator('.branch-indicator').count();
  console.log(`分岐インジケータ数: ${branchIndicators}`);
  
  if (branchIndicators === 0) {
    console.log('❌ 分岐インジケータが表示されていません');
    console.log('🔧 データ確認のため、追加調査を実行...');
    
    // コンポーネントの状態を確認
    await page.evaluate(() => {
      console.log('🔍 コンポーネント状態確認');
      // DOM要素から分岐データの存在を確認
      const moveItems = document.querySelectorAll('.move-item');
      console.log(`DOM内手順数: ${moveItems.length}`);
      
      moveItems.forEach((item, index) => {
        const text = item.textContent;
        const hasBranchIndicator = item.querySelector('.branch-indicator');
        console.log(`DOM手順[${index}]: "${text}" - インジケータ: ${!!hasBranchIndicator}`);
      });
    });
  } else {
    console.log('✅ 分岐インジケータが表示されています！');
  }

  console.log('=== ブラウザでゲーム1876の分岐確認完了 ===');
}); 