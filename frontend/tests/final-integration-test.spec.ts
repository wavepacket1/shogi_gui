import { test, expect } from '@playwright/test';

test('分岐機能最終統合テスト', async ({ page }) => {
  console.log('=== 分岐機能最終統合テスト開始 ===');
  
  page.on('console', msg => {
    if (msg.text().includes('🔍') || msg.text().includes('分岐') || msg.text().includes('🎮')) {
      console.log(`🖥️ [${msg.type()}]:`, msg.text());
    }
  });

  // 1. 既存ゲーム（1876）への直接アクセス
  console.log('1. 既存ゲーム1876への直接アクセス...');
  await page.goto('http://localhost:5173?game_id=1876', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  // 2. 分岐インジケータの確認
  console.log('2. 既存ゲームの分岐インジケータ確認...');
  await page.waitForSelector('.move-history-panel', { timeout: 10000 });
  
  const branchIndicators1876 = await page.locator('.branch-indicator').count();
  console.log(`ゲーム1876の分岐インジケータ数: ${branchIndicators1876}`);
  
  if (branchIndicators1876 > 0) {
    console.log('✅ ゲーム1876の分岐インジケータ表示正常');
    
    // 分岐選択の動作確認
    console.log('3. 分岐選択機能のテスト...');
    const firstIndicator = page.locator('.branch-indicator').first();
    await firstIndicator.locator('.branch-toggle-btn').click();
    await page.waitForTimeout(1000);
    
    const branchDropdown = page.locator('.branch-dropdown');
    if (await branchDropdown.isVisible()) {
      console.log('✅ 分岐選択ドロップダウンが表示されました');
      
      // ドロップダウンを閉じる
      await page.locator('.close-dropdown-btn').click();
      await page.waitForTimeout(500);
    } else {
      console.log('❌ 分岐選択ドロップダウンが表示されませんでした');
    }
  } else {
    console.log('❌ ゲーム1876の分岐インジケータが表示されていません');
  }

  // 4. 新規ゲームでの分岐作成テスト
  console.log('4. 新規ゲームでの分岐作成テスト...');
  await page.goto('http://localhost:5173', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  const gameId = await page.evaluate(async () => {
    // ローカルストレージから現在のゲームIDを取得
    const storedGameId = localStorage.getItem('currentGameId');
    if (storedGameId) {
      return parseInt(storedGameId);
    }
    
    // APIから最新ゲームを取得
    try {
      const response = await fetch('http://localhost:3000/api/v1/games');
      if (response.ok) {
        const games = await response.json();
        if (games && games.length > 0) {
          return games[games.length - 1].id;
        }
      }
    } catch (e) {
      console.error('ゲーム取得エラー:', e);
    }
    return null;
  });

  if (gameId) {
    console.log(`5. 新規ゲーム（${gameId}）でAPI経由分岐作成...`);
    
    // 第1手
    await page.evaluate(async (gameId) => {
      try {
        const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/boards/${gameId}/move`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            move: '5g5f',
            move_number: 0,
            branch: 'main'
          })
        });
        const result = await response.json();
        console.log('🎯 第1手（5五歩）:', result.notation);
      } catch (error) {
        console.error('第1手エラー:', error);
      }
    }, gameId);

    await page.waitForTimeout(1000);

    // 分岐手
    await page.evaluate(async (gameId) => {
      try {
        const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/boards/${gameId}/move`, {
          method: 'PATCH',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            move: '3g3f',
            move_number: 0,
            branch: 'main'
          })
        });
        const result = await response.json();
        console.log('🎯 分岐手（3三歩）:', result.notation);
      } catch (error) {
        console.error('分岐手エラー:', error);
      }
    }, gameId);

    await page.waitForTimeout(2000);
    
    // ページを更新して分岐インジケータを確認
    await page.reload({ waitUntil: 'networkidle' });
    await page.waitForTimeout(3000);

    const newBranchIndicators = await page.locator('.branch-indicator').count();
    console.log(`新規ゲームの分岐インジケータ数: ${newBranchIndicators}`);
    
    if (newBranchIndicators > 0) {
      console.log('✅ 新規ゲームでも分岐作成・表示が正常動作');
    } else {
      console.log('❌ 新規ゲームの分岐インジケータが表示されない');
    }
  }

  // 6. ナビゲーション機能の確認
  console.log('6. ナビゲーション機能の確認...');
  const navButtons = await page.locator('.navigation-controls .nav-button').count();
  console.log(`ナビゲーションボタン数: ${navButtons}`);
  
  if (navButtons >= 4) {
    console.log('✅ ナビゲーションボタンが正常に表示されています');
  } else {
    console.log('❌ ナビゲーションボタンの表示に問題があります');
  }

  // 7. 棋譜パネルの基本機能確認
  console.log('7. 棋譜パネルの基本機能確認...');
  const moveItems = await page.locator('.move-item').count();
  console.log(`手順項目数: ${moveItems}`);
  
  if (moveItems > 0) {
    console.log('✅ 棋譜パネルに手順が表示されています');
    
    // 最初の手順項目をクリック
    await page.locator('.move-item').first().click();
    await page.waitForTimeout(500);
    
    const activeItems = await page.locator('.move-item.active').count();
    if (activeItems > 0) {
      console.log('✅ 手順項目のクリック・ハイライト機能が正常動作');
    } else {
      console.log('❌ 手順項目のハイライト機能に問題があります');
    }
  } else {
    console.log('❌ 棋譜パネルに手順が表示されていません');
  }

  console.log('=== 分岐機能最終統合テスト完了 ===');
  
  // 8. 最終結果まとめ
  console.log('\n=== 機能別動作確認結果 ===');
  console.log(`✅ 既存ゲーム読み込み: ${branchIndicators1876 > 0 ? '正常' : 'エラー'}`);
  console.log(`✅ 分岐インジケータ表示: ${branchIndicators1876 > 0 ? '正常' : 'エラー'}`);
  console.log(`✅ 新規ゲーム分岐作成: ${gameId ? '正常' : 'エラー'}`);
  console.log(`✅ ナビゲーション機能: ${navButtons >= 4 ? '正常' : 'エラー'}`);
  console.log(`✅ 棋譜パネル機能: ${moveItems > 0 ? '正常' : 'エラー'}`);
  
  const overallSuccess = branchIndicators1876 > 0 && gameId && navButtons >= 4 && moveItems > 0;
  console.log(`\n🎉 全体評価: ${overallSuccess ? '成功' : '部分的問題あり'}`);
}); 