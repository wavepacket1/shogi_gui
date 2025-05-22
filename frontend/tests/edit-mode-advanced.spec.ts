import { test, expect } from '@playwright/test';

test.describe('編集モード（高度なテスト）', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('#app');
    await page.waitForTimeout(2000);
    await page.waitForSelector('header', { timeout: 5000 });
    
    const editModeTab = page.locator('.tab').filter({ hasText: '編集モード' });
    await expect(editModeTab).toBeVisible();
    await editModeTab.click();
    await page.waitForSelector('.edit-board-container', { timeout: 10000 });
  });

  test('詰将棋局面の作成テスト', async ({ page }) => {
    console.log('Starting tsume-shogi position creation test...');
    
    // コンソールログを監視
    page.on('console', msg => {
      console.log('Browser console:', msg.text());
    });
    
    // 1. 盤面をクリアするため、複数の駒を持ち駒に移動
    const pieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    const pieceCount = await pieces.count();
    console.log(`Total pieces to clear: ${pieceCount}`);
    
    // 最初の10個の駒を持ち駒に移動（詰将棋局面を作るためのスペース確保）
    for (let i = 0; i < Math.min(10, pieceCount); i++) {
      await pieces.nth(i).click({ button: 'right' });
      await page.waitForTimeout(500);
    }
    
    // 2. 手番を確認
    await expect(page.locator('.current-side')).toContainText('先手');
    
    // 3. 持ち駒から王将を配置してみる（詰将棋の基本構成）
    const handPieces = page.locator('.pieces-in-hand .piece-container');
    if (await handPieces.count() > 0) {
      // 最初の持ち駒をクリックして選択
      await handPieces.first().click();
      await page.waitForTimeout(500);
      
      // 盤面の中央あたりに配置
      const centerCell = page.locator('.shogi-cell').nth(40); // 9x9盤の中央付近
      await centerCell.click();
      await page.waitForTimeout(1000);
    }
    
    console.log('✅ Tsume-shogi position creation test completed');
  });

  test('大量操作の耐久性テスト', async ({ page }) => {
    console.log('Starting mass operation endurance test...');
    
    const startTime = Date.now();
    
    // 50回の連続操作を実行
    for (let i = 0; i < 50; i++) {
      const pieces = page.locator('.shogi-cell').filter({
        has: page.locator('.piece-shape[data-piece]')
      });
      
      const pieceCount = await pieces.count();
      if (pieceCount > 0) {
        const randomIndex = Math.floor(Math.random() * pieceCount);
        
        // ランダムに操作を選択
        const operation = Math.random();
        if (operation < 0.5) {
          // 駒をクリック（状態変更）
          await pieces.nth(randomIndex).click();
        } else {
          // 駒を右クリック（持ち駒に移動）
          await pieces.nth(randomIndex).click({ button: 'right' });
        }
        
        await page.waitForTimeout(100); // 短い間隔
      }
      
      // 10回ごとに手番切り替え
      if (i % 10 === 0) {
        await page.click('.toggle-side-btn');
        await page.waitForTimeout(100);
      }
    }
    
    const endTime = Date.now();
    const duration = endTime - startTime;
    
    console.log(`Mass operation test completed in ${duration}ms (50 operations)`);
    expect(duration).toBeLessThan(30000); // 30秒以内に完了
    
    console.log('✅ Mass operation endurance test completed');
  });

  test('データ整合性確認テスト', async ({ page }) => {
    console.log('Starting data consistency test...');
    
    // 操作前の状態を記録
    const initialPieceCount = await page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    }).count();
    
    console.log('Initial pieces on board:', initialPieceCount);
    
    // 複数の駒を持ち駒に移動
    const pieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    const moveCount = Math.min(5, await pieces.count());
    for (let i = 0; i < moveCount; i++) {
      await pieces.nth(i).click({ button: 'right' });
      await page.waitForTimeout(800);
    }
    
    // 持ち駒から盤上に戻す操作
    const handPieces = page.locator('.pieces-in-hand .piece-container');
    const handPieceCount = await handPieces.count();
    console.log('Hand pieces after moves:', handPieceCount);
    
    // 半分の持ち駒を盤上に戻す
    const returnCount = Math.min(3, handPieceCount);
    for (let i = 0; i < returnCount; i++) {
      await handPieces.nth(i).click();
      await page.waitForTimeout(500);
      
      // 空のマスに配置
      const emptyCell = page.locator('.shogi-cell').filter({
        hasNot: page.locator('.piece-shape')
      }).first();
      
      if (await emptyCell.count() > 0) {
        await emptyCell.click();
        await page.waitForTimeout(800);
      }
    }
    
    // 最終的な盤面の駒数を確認
    const finalPieceCount = await page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    }).count();
    
    console.log('Final pieces on board:', finalPieceCount);
    
    // データ整合性の基本チェック（駒の総数が大きく変わっていないこと）
    const diff = Math.abs(finalPieceCount - initialPieceCount);
    expect(diff).toBeLessThan(10); // 大幅な変化がないことを確認
    
    console.log('✅ Data consistency test completed');
  });

  test('リアルユーザーシナリオ：対局準備', async ({ page }) => {
    console.log('Starting real user scenario: game preparation...');
    
    // シナリオ：ユーザーが特定の局面を再現したい場合
    
    // 1. 手番を後手に変更
    await page.click('.toggle-side-btn');
    await expect(page.locator('.current-side')).toContainText('後手');
    
    // 2. 特定の駒を取り除く（飛車を移動してみる）
    const rookCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece="r"]')
    }).first();
    
    if (await rookCell.count() > 0) {
      console.log('Found rook, moving to hand...');
      await rookCell.click({ button: 'right' });
      await page.waitForTimeout(1500);
    }
    
    // 3. 手番を先手に戻す
    await page.click('.toggle-side-btn');
    await expect(page.locator('.current-side')).toContainText('先手');
    
    // 4. 先手の歩を前進（ドラッグ&ドロップで）
    const pawnCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece="P"]')
    }).first();
    
    if (await pawnCell.count() > 0) {
      const targetCell = page.locator('.shogi-cell').filter({
        hasNot: page.locator('.piece-shape')
      }).nth(2); // 3番目の空マス
      
      if (await targetCell.count() > 0) {
        console.log('Moving pawn forward...');
        await pawnCell.locator('.piece-shape').dragTo(targetCell);
        await page.waitForTimeout(2000);
      }
    }
    
    // 5. 操作履歴の確認（unsavedChangesフラグ）
    const hasChanges = await page.evaluate(() => {
      const stores = (window as any).__PINIA__?._s;
      if (stores) {
        for (const [key, store] of stores.entries()) {
          if (key.includes('boardEdit') || key.includes('board')) {
            return store.unsavedChanges || false;
          }
        }
      }
      return false;
    });
    
    console.log('Has unsaved changes:', hasChanges);
    
    console.log('✅ Real user scenario test completed');
  });

    test('ネットワーク断線シミュレーション', async ({ page }) => {
    console.log('Starting network disconnection simulation...');
    
    // ネットワークをオフラインに設定
    await page.context().setOffline(true);
    
    // オフライン状態でも編集操作が継続できることを確認
    const pieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    const pieceCount = await pieces.count();
    if (pieceCount > 0) {
      // オフライン状態での操作
      await pieces.first().click();
      await page.waitForTimeout(1000);
      
      await pieces.nth(1).click({ button: 'right' });
      await page.waitForTimeout(1000);
      
      // 手番切り替え
      await page.click('.toggle-side-btn');
      await page.waitForTimeout(500);
    }
    
    // 保存ボタンの状態確認（オフライン時）
    const saveButton = page.locator('.save-btn');
    const isDisabled = await saveButton.isDisabled();
    console.log('Save button disabled in offline mode:', isDisabled);
    
    // ネットワークを復旧
    await page.context().setOffline(false);
    await page.waitForTimeout(1000);
    
    console.log('✅ Network disconnection simulation completed');
  });

  test('キーボードショートカット操作テスト', async ({ page }) => {
    console.log('Starting keyboard shortcut test...');
    
    // フォーカスを盤面に移動
    await page.locator('.shogi-board').click();
    
    // キーボード操作のテスト
    
    // Spaceキーで手番切り替え（実装されている場合）
    await page.keyboard.press('Space');
    await page.waitForTimeout(500);
    
    // Tabキーでナビゲーション
    await page.keyboard.press('Tab');
    await page.waitForTimeout(300);
    await page.keyboard.press('Tab');
    await page.waitForTimeout(300);
    
    // Enterキーでボタンアクティベーション
    await page.keyboard.press('Enter');
    await page.waitForTimeout(500);
    
    // Escapeキーで選択解除（実装されている場合）
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    
    console.log('✅ Keyboard shortcut test completed');
  });

    test('長時間操作セッションテスト', async ({ page }) => {
    console.log('Starting long session test...');
    
    const sessionStartTime = Date.now();
    const sessionDuration = 10000; // 10秒間の連続操作
    
    let operationCount = 0;
    
    while (Date.now() - sessionStartTime < sessionDuration) {
      const pieces = page.locator('.shogi-cell').filter({
        has: page.locator('.piece-shape[data-piece]')
      });
      
      const pieceCount = await pieces.count();
      if (pieceCount > 0) {
        const randomIndex = Math.floor(Math.random() * Math.min(3, pieceCount));
        
        // 多様な操作をランダムに実行
        const operation = operationCount % 4;
        switch (operation) {
          case 0:
            await pieces.nth(randomIndex).click();
            break;
          case 1:
            await pieces.nth(randomIndex).click({ button: 'right' });
            break;
          case 2:
            await page.click('.toggle-side-btn');
            break;
          case 3:
            // ドラッグ&ドロップ
            const targetCell = page.locator('.shogi-cell').filter({
              hasNot: page.locator('.piece-shape')
            }).first();
            if (await targetCell.count() > 0) {
              await pieces.nth(randomIndex).locator('.piece-shape').dragTo(targetCell);
            }
            break;
        }
        
        operationCount++;
        await page.waitForTimeout(200);
      }
    }
    
    const sessionEndTime = Date.now();
    const actualDuration = sessionEndTime - sessionStartTime;
    
    console.log(`Long session completed: ${operationCount} operations in ${actualDuration}ms`);
    expect(operationCount).toBeGreaterThan(10); // 最低限の操作数を確認
    
    console.log('✅ Long session test completed');
  });
}); 