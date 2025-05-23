const { test, expect } = require('@playwright/test');

test('Check piece orientation in edit mode', async ({ page }) => {
  // アプリケーションを起動 - モードパラメータを追加
  await page.goto('http://localhost:5173/?mode=edit&gameId=1');
  
  // 読み込み待機
  await page.waitForSelector('.shogi-board');
  
  // 後手（白）の駒をドラッグ＆ドロップするテスト
  console.log('テスト開始 - 後手の駒をドラッグアンドドロップします');
  
  // スクリーンショットを取得（ドラッグ前）
  await page.screenshot({ path: 'before_drag.png' });
  console.log('ドラッグ前のスクリーンショットを保存しました: before_drag.png');
  
  // 1-2行目の駒（後手の飛車）を取得
  const whitePiece = await page.locator('.shogi-board .shogi-row:nth-child(2) .shogi-cell:nth-child(2) .piece-shape');
  
  // クラスを確認
  const initialClass = await whitePiece.evaluate(el => Array.from(el.classList));
  console.log('ドラッグ前の駒のクラス:', initialClass);
  
  // 移動先を取得（中央付近の空きマス）
  const targetCell = await page.locator('.shogi-board .shogi-row:nth-child(5) .shogi-cell:nth-child(5)');
  
  // ドラッグ＆ドロップ操作
  await whitePiece.dragTo(targetCell);
  
  // 少し待つ
  await page.waitForTimeout(1000);
  
  // スクリーンショットを取得（ドラッグ後）
  await page.screenshot({ path: 'after_drag.png' });
  console.log('ドラッグ後のスクリーンショットを保存しました: after_drag.png');
  
  // 移動先にある駒のクラスを取得
  const movedPiece = await page.locator('.shogi-board .shogi-row:nth-child(5) .shogi-cell:nth-child(5) .piece-shape');
  const finalClass = await movedPiece.evaluate(el => Array.from(el.classList));
  console.log('ドラッグ後の駒のクラス:', finalClass);
  
  // 結果を表示
  const hasWClass = finalClass.includes('w');
  console.log('移動後の駒は白向き（w クラス）を持っていますか？:', hasWClass);
  
  // テスト結果を確認
  expect(hasWClass).toBeTruthy();
}); 