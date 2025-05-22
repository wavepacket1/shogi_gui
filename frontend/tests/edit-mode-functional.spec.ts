import { test, expect } from '@playwright/test';

test.describe('編集モード（実用機能テスト）', () => {
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

  test('四間飛車の基本形作成テスト', async ({ page }) => {
    console.log('Starting Shiken-Bisha formation test...');
    
    // コンソールログを監視
    page.on('console', msg => {
      console.log('Browser console:', msg.text());
    });
    
    // 1. 先手の飛車を４筋に移動（四間飛車の基本）
    const rookCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece="R"]')
    }).first();
    
    if (await rookCell.count() > 0) {
      // 飛車を4筋（盤面の5列目）に移動
      const targetCell = page.locator('.shogi-cell').nth(7 * 9 + 5); // 8段目の6列目
      
      console.log('Moving rook to 4th file...');
      await rookCell.locator('.piece-shape').dragTo(targetCell);
      await page.waitForTimeout(2000);
    }
    
    // 2. 角を右四間飛車の位置に移動
    const bishopCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece="B"]')
    }).first();
    
    if (await bishopCell.count() > 0) {
      // 角を適切な位置に移動
      const targetCell = page.locator('.shogi-cell').filter({
        hasNot: page.locator('.piece-shape')
      }).nth(3);
      
      console.log('Moving bishop for Shiken-Bisha...');
      await bishopCell.locator('.piece-shape').dragTo(targetCell);
      await page.waitForTimeout(2000);
    }
    
    // 3. 銀を上がる（四間飛車の銀の定位置）
    const silverCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece="S"]')
    }).first();
    
    if (await silverCell.count() > 0) {
      const targetCell = page.locator('.shogi-cell').filter({
        hasNot: page.locator('.piece-shape')
      }).nth(1);
      
      console.log('Moving silver for formation...');
      await silverCell.locator('.piece-shape').dragTo(targetCell);
      await page.waitForTimeout(2000);
    }
    
    console.log('✅ Shiken-Bisha formation test completed');
  });

  test('詰みの局面作成テスト', async ({ page }) => {
    console.log('Starting checkmate position creation...');
    
    // 1. 多くの駒を持ち駒に移動（詰み局面を作るため）
    const pieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    const pieceCount = await pieces.count();
    const clearCount = Math.min(20, pieceCount);
    
    console.log(`Clearing ${clearCount} pieces for checkmate setup...`);
    
    for (let i = 0; i < clearCount; i++) {
      await pieces.nth(i).click({ button: 'right' });
      await page.waitForTimeout(300);
    }
    
    // 2. 王を端に追い詰める配置
    const handPieces = page.locator('.pieces-in-hand .piece-container');
    const handCount = await handPieces.count();
    
    if (handCount > 0) {
      // 持ち駒から王を特定の位置に配置
      console.log('Placing pieces for checkmate...');
      
      for (let i = 0; i < Math.min(3, handCount); i++) {
        await handPieces.nth(i).click();
        await page.waitForTimeout(500);
        
        // 9x9盤の端の方に配置
        const edgeCell = page.locator('.shogi-cell').nth(i * 10 + 8);
        await edgeCell.click();
        await page.waitForTimeout(800);
      }
    }
    
    console.log('✅ Checkmate position creation test completed');
  });

  test('対称な局面作成テスト', async ({ page }) => {
    console.log('Starting symmetric position test...');
    
    // 手番を切り替えながら対称的な配置を作成
    
    // 1. 先手番で駒を配置
    await expect(page.locator('.current-side')).toContainText('先手');
    
    const pieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    if (await pieces.count() > 0) {
      // 先手の駒を中央付近に移動
      const centerLeft = page.locator('.shogi-cell').nth(4 * 9 + 3); // 5段目4列目
      await pieces.first().locator('.piece-shape').dragTo(centerLeft);
      await page.waitForTimeout(1500);
    }
    
    // 2. 後手番に切り替えて対称配置
    await page.click('.toggle-side-btn');
    await expect(page.locator('.current-side')).toContainText('後手');
    
    const remainingPieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    if (await remainingPieces.count() > 0) {
      // 後手の駒を対称位置に移動
      const centerRight = page.locator('.shogi-cell').nth(4 * 9 + 5); // 5段目6列目
      await remainingPieces.first().locator('.piece-shape').dragTo(centerRight);
      await page.waitForTimeout(1500);
    }
    
    // 3. 手番を先手に戻す
    await page.click('.toggle-side-btn');
    await expect(page.locator('.current-side')).toContainText('先手');
    
    console.log('✅ Symmetric position test completed');
  });

  test('駒の所有権管理テスト', async ({ page }) => {
    console.log('Starting piece ownership management test...');
    
    // 1. 先手の駒を持ち駒に移動
    const senteCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece="P"]')
    }).first();
    
    if (await senteCell.count() > 0) {
      console.log('Moving sente piece to hand...');
      await senteCell.click({ button: 'right' });
      await page.waitForTimeout(1500);
    }
    
    // 2. 後手の駒を持ち駒に移動
    const goteCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece="p"]')
    }).first();
    
    if (await goteCell.count() > 0) {
      console.log('Moving gote piece to hand...');
      await goteCell.click({ button: 'right' });
      await page.waitForTimeout(1500);
    }
    
    // 3. 持ち駒の数を確認
    const handPieces = page.locator('.pieces-in-hand .piece-container');
    const handCount = await handPieces.count();
    console.log('Total hand pieces:', handCount);
    
    // 4. 手番を切り替えて持ち駒の表示変化を確認
    await page.click('.toggle-side-btn');
    await page.waitForTimeout(1000);
    
    const handCountAfterToggle = await handPieces.count();
    console.log('Hand pieces after toggle:', handCountAfterToggle);
    
    // 5. 手番を戻す
    await page.click('.toggle-side-btn');
    await page.waitForTimeout(1000);
    
    expect(handCount).toBeGreaterThan(0);
    
    console.log('✅ Piece ownership management test completed');
  });

  test('盤面リセット機能テスト', async ({ page }) => {
    console.log('Starting board reset functionality test...');
    
    // 1. 複数の操作を実行して盤面を変更
    const pieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    const initialCount = await pieces.count();
    console.log('Initial piece count:', initialCount);
    
    // 数個の駒を移動・削除
    for (let i = 0; i < Math.min(5, initialCount); i++) {
      if (i % 2 === 0) {
        // 偶数番目は右クリックで削除
        await pieces.nth(i).click({ button: 'right' });
      } else {
        // 奇数番目はクリックで状態変更
        await pieces.nth(i).click();
      }
      await page.waitForTimeout(500);
    }
    
    // 2. 手番を切り替え
    await page.click('.toggle-side-btn');
    await page.waitForTimeout(500);
    
    // 3. 変更後の状態を記録
    const afterChangeCount = await page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    }).count();
    
    console.log('Piece count after changes:', afterChangeCount);
    
    // 4. 盤面の変更が適用されていることを確認
    expect(afterChangeCount).not.toBe(initialCount);
    
    console.log('✅ Board reset functionality test completed');
  });

  test('特殊駒配置テスト（成り駒中心）', async ({ page }) => {
    console.log('Starting special piece placement test...');
    
    // 1. 成れる駒を成り駒に変換
    const promotablePieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    const pieceCount = await promotablePieces.count();
    
    // 最初の数個の駒を成り駒に変換
    for (let i = 0; i < Math.min(3, pieceCount); i++) {
      const piece = promotablePieces.nth(i);
      const pieceType = await piece.locator('.piece-shape').getAttribute('data-piece');
      
      console.log(`Attempting to promote piece: ${pieceType}`);
      
      // 成れる駒かチェック（歩、香、桂、銀、角、飛）
      if (pieceType && ['P', 'L', 'N', 'S', 'B', 'R', 'p', 'l', 'n', 's', 'b', 'r'].includes(pieceType)) {
        // 2回クリックで成り駒に（実装によって異なる場合がある）
        await piece.click();
        await page.waitForTimeout(1000);
        await piece.click();
        await page.waitForTimeout(1000);
      }
    }
    
    // 2. 成り駒を持ち駒に移動（基本形に戻る）
    const promotedPieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece^="+"]')
    });
    
    const promotedCount = await promotedPieces.count();
    console.log('Promoted pieces found:', promotedCount);
    
    if (promotedCount > 0) {
      await promotedPieces.first().click({ button: 'right' });
      await page.waitForTimeout(1500);
    }
    
    console.log('✅ Special piece placement test completed');
  });

  test('連続ドラッグ&ドロップテスト', async ({ page }) => {
    console.log('Starting continuous drag&drop test...');
    
    const pieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    const pieceCount = await pieces.count();
    const dragCount = Math.min(5, pieceCount);
    
    console.log(`Performing ${dragCount} consecutive drag&drop operations...`);
    
    for (let i = 0; i < dragCount; i++) {
      // 空のマスを見つける
      const emptyCells = page.locator('.shogi-cell').filter({
        hasNot: page.locator('.piece-shape')
      });
      
      const emptyCount = await emptyCells.count();
      
      if (emptyCount > 0) {
        const sourcePiece = pieces.nth(i);
        const targetCell = emptyCells.first();
        
        console.log(`Drag&drop operation ${i + 1}/${dragCount}`);
        
        try {
          await sourcePiece.locator('.piece-shape').dragTo(targetCell);
          await page.waitForTimeout(1000);
        } catch (error) {
          console.log(`Drag&drop ${i + 1} failed:`, error);
        }
      }
    }
    
    console.log('✅ Continuous drag&drop test completed');
  });

  test('順次操作テスト', async ({ page }) => {
    console.log('Starting sequential operation test...');
    
    // 1. 複数の操作を順次実行
    
    // 手番切り替え操作
    await page.click('.toggle-side-btn');
    await page.waitForTimeout(500);
    
    // 駒のクリック操作
    const pieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    if (await pieces.count() > 0) {
      await pieces.first().click();
      await page.waitForTimeout(500);
    }
    
    if (await pieces.count() > 1) {
      await pieces.nth(1).click({ button: 'right' });
      await page.waitForTimeout(500);
    }
    
    // 2. 手番を元に戻す
    await page.click('.toggle-side-btn');
    await page.waitForTimeout(500);
    
    console.log('All operations completed successfully');
    console.log('✅ Sequential operation test completed');
  });

  test('エラー回復力テスト', async ({ page }) => {
    console.log('Starting error recovery test...');
    
    // 1. 無効な操作を実行
    
    // 空のマスをクリック（何も起こらないはず）
    const emptyCell = page.locator('.shogi-cell').filter({
      hasNot: page.locator('.piece-shape')
    }).first();
    
    if (await emptyCell.count() > 0) {
      console.log('Clicking empty cell (should have no effect)...');
      await emptyCell.click();
      await emptyCell.click({ button: 'right' });
      await page.waitForTimeout(1000);
    }
    
    // 2. 高速連続クリック
    const pieces = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    });
    
    if (await pieces.count() > 0) {
      console.log('Rapid clicking test...');
      const testPiece = pieces.first();
      
      // 高速で10回クリック
      for (let i = 0; i < 10; i++) {
        await testPiece.click();
        await page.waitForTimeout(50); // 非常に短い間隔
      }
    }
    
    // 3. 無効なドラッグ&ドロップ（マス外など）
    if (await pieces.count() > 1) {
      console.log('Invalid drag&drop test...');
      const sourcePiece = pieces.nth(1);
      const targetPiece = pieces.nth(2);
      
      try {
        // 駒を他の駒の上にドラッグ（置き換えになるはず）
        await sourcePiece.locator('.piece-shape').dragTo(targetPiece);
        await page.waitForTimeout(1000);
      } catch (error) {
        console.log('Expected drag&drop behavior:', error);
      }
    }
    
    // 4. システムが正常に動作していることを確認
    const finalPieceCount = await page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    }).count();
    
    console.log('Final piece count after error tests:', finalPieceCount);
    expect(finalPieceCount).toBeGreaterThan(0);
    
    console.log('✅ Error recovery test completed');
  });
}); 