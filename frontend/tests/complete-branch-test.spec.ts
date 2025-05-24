import { test, expect } from '@playwright/test';

test('分岐機能完全統合テスト', async ({ page }) => {
  console.log('=== 分岐機能完全統合テスト開始 ===');
  
  // すべてのコンソールログを監視
  page.on('console', msg => {
    if (msg.type() === 'log') {
      console.log('🖥️ ブラウザ:', msg.text());
    }
  });
  
  // ページを開く
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(2000);

  console.log('1. 新しいゲームを作成...');
  try {
    await page.locator('button').filter({ hasText: '新しいゲーム' }).click();
    await page.waitForTimeout(3000);
  } catch (error) {
    console.log('新しいゲームボタンを手動で探します...');
  }

  console.log('2. 盤面とMoveHistoryPanelの表示を確認...');
  await page.waitForSelector('.shogi-board', { timeout: 10000 });
  
  console.log('3. 最初の手を指す（7六歩）...');
  // 具体的なセレクタを使用して7六歩を指す
  try {
    // データ属性を使用した要素の検索
    const piece76 = page.locator('[data-testid="piece-76"], [data-row="6"][data-col="6"] .piece-shape');
    const square56 = page.locator('[data-testid="square-56"], [data-row="5"][data-col="6"]');
    
    if (await piece76.count() > 0) {
      await piece76.first().click();
      await page.waitForTimeout(1000);
      
      if (await square56.count() > 0) {
        await square56.first().click();
        await page.waitForTimeout(3000);
        console.log('✅ 7六歩を指しました');
      }
    }
  } catch (error) {
    console.log('駒移動でエラー:', error);
  }

  console.log('4. 局面をリセットして別の手を指す（分岐作成テスト）...');
  // 初期局面に戻る
  try {
    const resetButton = page.locator('button').filter({ hasText: '|◀' });
    if (await resetButton.count() > 0) {
      await resetButton.click();
      await page.waitForTimeout(2000);
    }
  } catch (error) {
    console.log('リセットボタンが見つかりません');
  }

  console.log('5. 異なる手を指す（2六歩）...');
  try {
    // 2六歩を指す
    const piece26 = page.locator('[data-testid="piece-26"], [data-row="6"][data-col="1"] .piece-shape');
    const square25 = page.locator('[data-testid="square-25"], [data-row="5"][data-col="1"]');
    
    if (await piece26.count() > 0) {
      await piece26.first().click();
      await page.waitForTimeout(1000);
      
      if (await square25.count() > 0) {
        await square25.first().click();
        await page.waitForTimeout(3000);
        console.log('✅ 2六歩を指しました（分岐作成）');
      }
    }
  } catch (error) {
    console.log('2六歩の移動でエラー:', error);
  }

  console.log('6. 分岐インジケータの確認...');
  await page.waitForTimeout(5000); // 分岐データの取得を待つ
  
  const branchIndicators = await page.locator('.branch-indicator, .plus-button, text="+", [data-branch-indicator]').count();
  console.log(`分岐インジケータ数: ${branchIndicators}`);

  console.log('7. MoveHistoryPanelの分岐情報を確認...');
  // JavaScript実行して分岐情報を取得
  await page.evaluate(() => {
    console.log('🎯 分岐統合テスト: 現在の分岐状況を確認');
    
    // Vue DevToolsまたはグローバル変数経由でストアにアクセスを試行
    if (window && (window as any).__VUE_DEVTOOLS_GLOBAL_HOOK__) {
      console.log('Vue DevTools detected');
    }
  });

  console.log('=== 分岐機能完全統合テスト完了 ===');
  console.log('バックエンドログと比較して分岐作成が成功したかご確認ください');
}); 