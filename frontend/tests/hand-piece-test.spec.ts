import { test, expect } from '@playwright/test';

test.describe('持ち駒テスト', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('http://localhost:5173');
    
    // 編集モードに切り替え
    await page.click('.tab:has-text("編集モード")');
    await page.waitForSelector('.edit-board-container', { timeout: 10000 });
    await page.waitForTimeout(2000);
  });

  test('先手の手番で右クリックした駒は先手の駒台に追加される', async ({ page }) => {
    // 先手の手番であることを確認
    await expect(page.locator('.current-side')).toContainText('先手');
    
    // 初期の先手持ち駒数を取得
    const initialBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
    console.log('初期の先手持ち駒数:', initialBlackPieces);
    
    // 盤上の駒を右クリック
    const pieceCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    }).first();
    
    const pieceType = await pieceCell.locator('.piece-shape').getAttribute('data-piece');
    console.log('右クリックする駒:', pieceType);
    
    await pieceCell.click({ button: 'right' });
    await page.waitForTimeout(1500);
    
    // 右クリック後の先手持ち駒数を取得
    const afterBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
    console.log('右クリック後の先手持ち駒数:', afterBlackPieces);
    
    // 先手の駒台に駒が追加されたことを確認
    expect(afterBlackPieces).toBeGreaterThan(initialBlackPieces);
  });

  test('後手の手番で右クリックした駒は後手の駒台に追加される', async ({ page }) => {
    // 後手の手番に切り替え
    await page.click('.toggle-side-btn');
    await expect(page.locator('.current-side')).toContainText('後手');
    
    // 初期の後手持ち駒数を取得
    const initialWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
    console.log('初期の後手持ち駒数:', initialWhitePieces);
    
    // 盤上の駒を右クリック
    const pieceCell = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    }).first();
    
    const pieceType = await pieceCell.locator('.piece-shape').getAttribute('data-piece');
    console.log('右クリックする駒:', pieceType);
    
    await pieceCell.click({ button: 'right' });
    await page.waitForTimeout(1500);
    
    // 右クリック後の後手持ち駒数を取得
    const afterWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
    console.log('右クリック後の後手持ち駒数:', afterWhitePieces);
    
    // 後手の駒台に駒が追加されたことを確認
    expect(afterWhitePieces).toBeGreaterThan(initialWhitePieces);
  });

  test('手番を切り替えながら複数の駒を右クリックして、それぞれ適切な駒台に追加される', async ({ page }) => {
    // 先手の手番から開始
    await expect(page.locator('.current-side')).toContainText('先手');
    
    // 初期の持ち駒数を記録
    const initialBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
    const initialWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
    
    console.log('初期状態 - 先手持ち駒:', initialBlackPieces, '後手持ち駒:', initialWhitePieces);
    
    // 1. 先手の手番で駒を右クリック
    const firstPiece = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    }).first();
    
    await firstPiece.click({ button: 'right' });
    await page.waitForTimeout(1000);
    
    // 先手の駒台に追加されたことを確認
    const blackAfterFirst = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
    expect(blackAfterFirst).toBeGreaterThan(initialBlackPieces);
    
    // 2. 後手の手番に切り替え
    await page.click('.toggle-side-btn');
    await expect(page.locator('.current-side')).toContainText('後手');
    
    // 3. 後手の手番で別の駒を右クリック
    const secondPiece = page.locator('.shogi-cell').filter({
      has: page.locator('.piece-shape[data-piece]')
    }).first();
    
    await secondPiece.click({ button: 'right' });
    await page.waitForTimeout(1000);
    
    // 後手の駒台に追加されたことを確認
    const whiteAfterSecond = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
    expect(whiteAfterSecond).toBeGreaterThan(initialWhitePieces);
    
    // 最終状態をログ出力
    const finalBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
    const finalWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
    
    console.log('最終状態 - 先手持ち駒:', finalBlackPieces, '後手持ち駒:', finalWhitePieces);
    
    // 両方の駒台に駒が追加されたことを確認
    expect(finalBlackPieces).toBeGreaterThan(initialBlackPieces);
    expect(finalWhitePieces).toBeGreaterThan(initialWhitePieces);
  });

  test('後手の駒を右クリックして駒台配置を確認するテスト', async ({ page }) => {
    console.log('=== 後手の駒右クリック詳細テスト開始 ===');
    
    // 初期の持ち駒数を記録
    const initialBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
    const initialWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
    console.log('初期状態 - 先手持ち駒:', initialBlackPieces, '後手持ち駒:', initialWhitePieces);
    
    // 盤面上の全ての駒を確認
    const allPieces = await page.locator('.piece-shape[data-piece]').all();
    console.log('盤面上の駒数:', allPieces.length);
    
    // 最初の5個の駒の情報を表示
    for (let i = 0; i < Math.min(allPieces.length, 10); i++) {
      const piece = await allPieces[i].getAttribute('data-piece');
      const owner = await allPieces[i].getAttribute('data-owner');
      console.log(`駒${i+1}: ${piece} (所有者: ${owner})`);
      
      // 後手の駒（小文字）を見つけたら右クリック
      if (piece && piece === piece.toLowerCase() && !piece.startsWith('+')) {
        console.log(`後手の駒を発見: ${piece}, 右クリックします`);
        
        await allPieces[i].click({ button: 'right' });
        await page.waitForTimeout(1500);
        
        // 右クリック後の持ち駒数を確認
        const afterBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
        const afterWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
        console.log('右クリック後 - 先手持ち駒:', afterBlackPieces, '後手持ち駒:', afterWhitePieces);
        
        const blackIncreased = afterBlackPieces > initialBlackPieces;
        const whiteIncreased = afterWhitePieces > initialWhitePieces;
        
        console.log('先手駒台に追加された:', blackIncreased);
        console.log('後手駒台に追加された:', whiteIncreased);
        
        // 後手の駒は後手の駒台に追加されるべき
        expect(whiteIncreased).toBe(true);
        expect(blackIncreased).toBe(false);
        
        break; // 1個目が見つかったら終了
      }
    }
  });
}); 