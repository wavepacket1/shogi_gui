# Test info

- Name: 持ち駒テスト >> 手番を切り替えながら複数の駒を右クリックして、それぞれ適切な駒台に追加される
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\hand-piece-test.spec.ts:78:3

# Error details

```
Error: expect(received).toBeGreaterThan(expected)

Expected: > 0
Received:   0
    at C:\Users\kinoko\shogi_gui\frontend\tests\hand-piece-test.spec.ts:98:29
```

# Page snapshot

```yaml
- banner: 対局モード 編集モード 検討モード
- text: "現在: 先手"
- button "手番切り替え"
- button "保存"
- text: "ゲームID: 2138 未保存の変更あり 香 桂 銀 金 玉 金 銀 桂 香 飛 角 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 角 飛 香 桂 銀 金 王 金 銀 桂 香"
- paragraph: "右クリック: 盤上の駒を持ち駒に戻す"
- paragraph: "クリック: 駒の状態変更（成り不成反転 ↔ 向き反転を繰り返し）"
- paragraph: "持ち駒クリック→マスクリック: 持ち駒を盤上に配置"
```

# Test source

```ts
   1 | import { test, expect } from '@playwright/test';
   2 |
   3 | test.describe('持ち駒テスト', () => {
   4 |   test.beforeEach(async ({ page }) => {
   5 |     await page.goto('/');
   6 |     
   7 |     // ページが読み込まれるまで待機
   8 |     await page.waitForSelector('#app');
   9 |     await page.waitForTimeout(2000);
   10 |     
   11 |     // MenuBarが存在することを確認
   12 |     await page.waitForSelector('header', { timeout: 5000 });
   13 |     
   14 |     // 編集モードに切り替え
   15 |     const editModeTab = page.locator('.tab').filter({ hasText: '編集モード' });
   16 |     await expect(editModeTab).toBeVisible();
   17 |     await editModeTab.click();
   18 |     
   19 |     await page.waitForSelector('.edit-board-container', { timeout: 10000 });
   20 |     await page.waitForTimeout(2000);
   21 |   });
   22 |
   23 |   test('先手の手番で右クリックした駒は先手の駒台に追加される', async ({ page }) => {
   24 |     // 先手の手番であることを確認
   25 |     await expect(page.locator('.current-side')).toContainText('先手');
   26 |     
   27 |     // 初期の先手持ち駒数を取得
   28 |     const initialBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
   29 |     console.log('初期の先手持ち駒数:', initialBlackPieces);
   30 |     
   31 |     // 盤上の駒を右クリック
   32 |     const pieceCell = page.locator('.shogi-cell').filter({
   33 |       has: page.locator('.piece-shape[data-piece]')
   34 |     }).first();
   35 |     
   36 |     const pieceType = await pieceCell.locator('.piece-shape').getAttribute('data-piece');
   37 |     console.log('右クリックする駒:', pieceType);
   38 |     
   39 |     await pieceCell.click({ button: 'right' });
   40 |     await page.waitForTimeout(1500);
   41 |     
   42 |     // 右クリック後の先手持ち駒数を取得
   43 |     const afterBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
   44 |     console.log('右クリック後の先手持ち駒数:', afterBlackPieces);
   45 |     
   46 |     // 先手の駒台に駒が追加されたことを確認
   47 |     expect(afterBlackPieces).toBeGreaterThan(initialBlackPieces);
   48 |   });
   49 |
   50 |   test('後手の手番で右クリックした駒は後手の駒台に追加される', async ({ page }) => {
   51 |     // 後手の手番に切り替え
   52 |     await page.click('.toggle-side-btn');
   53 |     await expect(page.locator('.current-side')).toContainText('後手');
   54 |     
   55 |     // 初期の後手持ち駒数を取得
   56 |     const initialWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
   57 |     console.log('初期の後手持ち駒数:', initialWhitePieces);
   58 |     
   59 |     // 盤上の駒を右クリック
   60 |     const pieceCell = page.locator('.shogi-cell').filter({
   61 |       has: page.locator('.piece-shape[data-piece]')
   62 |     }).first();
   63 |     
   64 |     const pieceType = await pieceCell.locator('.piece-shape').getAttribute('data-piece');
   65 |     console.log('右クリックする駒:', pieceType);
   66 |     
   67 |     await pieceCell.click({ button: 'right' });
   68 |     await page.waitForTimeout(1500);
   69 |     
   70 |     // 右クリック後の後手持ち駒数を取得
   71 |     const afterWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
   72 |     console.log('右クリック後の後手持ち駒数:', afterWhitePieces);
   73 |     
   74 |     // 後手の駒台に駒が追加されたことを確認
   75 |     expect(afterWhitePieces).toBeGreaterThan(initialWhitePieces);
   76 |   });
   77 |
   78 |   test('手番を切り替えながら複数の駒を右クリックして、それぞれ適切な駒台に追加される', async ({ page }) => {
   79 |     // 先手の手番から開始
   80 |     await expect(page.locator('.current-side')).toContainText('先手');
   81 |     
   82 |     // 初期の持ち駒数を記録
   83 |     const initialBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
   84 |     const initialWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
   85 |     
   86 |     console.log('初期状態 - 先手持ち駒:', initialBlackPieces, '後手持ち駒:', initialWhitePieces);
   87 |     
   88 |     // 1. 先手の手番で駒を右クリック
   89 |     const firstPiece = page.locator('.shogi-cell').filter({
   90 |       has: page.locator('.piece-shape[data-piece]')
   91 |     }).first();
   92 |     
   93 |     await firstPiece.click({ button: 'right' });
   94 |     await page.waitForTimeout(1000);
   95 |     
   96 |     // 先手の駒台に追加されたことを確認
   97 |     const blackAfterFirst = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
>  98 |     expect(blackAfterFirst).toBeGreaterThan(initialBlackPieces);
      |                             ^ Error: expect(received).toBeGreaterThan(expected)
   99 |     
  100 |     // 2. 後手の手番に切り替え
  101 |     await page.click('.toggle-side-btn');
  102 |     await expect(page.locator('.current-side')).toContainText('後手');
  103 |     
  104 |     // 3. 後手の手番で別の駒を右クリック
  105 |     const secondPiece = page.locator('.shogi-cell').filter({
  106 |       has: page.locator('.piece-shape[data-piece]')
  107 |     }).first();
  108 |     
  109 |     await secondPiece.click({ button: 'right' });
  110 |     await page.waitForTimeout(1000);
  111 |     
  112 |     // 後手の駒台に追加されたことを確認
  113 |     const whiteAfterSecond = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
  114 |     expect(whiteAfterSecond).toBeGreaterThan(initialWhitePieces);
  115 |     
  116 |     // 最終状態をログ出力
  117 |     const finalBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
  118 |     const finalWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
  119 |     
  120 |     console.log('最終状態 - 先手持ち駒:', finalBlackPieces, '後手持ち駒:', finalWhitePieces);
  121 |     
  122 |     // 両方の駒台に駒が追加されたことを確認
  123 |     expect(finalBlackPieces).toBeGreaterThan(initialBlackPieces);
  124 |     expect(finalWhitePieces).toBeGreaterThan(initialWhitePieces);
  125 |   });
  126 |
  127 |   test('後手の駒を右クリックして駒台配置を確認するテスト', async ({ page }) => {
  128 |     console.log('=== 後手の駒右クリック詳細テスト開始 ===');
  129 |     
  130 |     // 初期の持ち駒数を記録
  131 |     const initialBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
  132 |     const initialWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
  133 |     console.log('初期状態 - 先手持ち駒:', initialBlackPieces, '後手持ち駒:', initialWhitePieces);
  134 |     
  135 |     // 盤面上の全ての駒を確認
  136 |     const allPieces = await page.locator('.piece-shape[data-piece]').all();
  137 |     console.log('盤面上の駒数:', allPieces.length);
  138 |     
  139 |     // 最初の5個の駒の情報を表示
  140 |     for (let i = 0; i < Math.min(allPieces.length, 10); i++) {
  141 |       const piece = await allPieces[i].getAttribute('data-piece');
  142 |       const owner = await allPieces[i].getAttribute('data-owner');
  143 |       console.log(`駒${i+1}: ${piece} (所有者: ${owner})`);
  144 |       
  145 |       // 後手の駒（小文字）を見つけたら右クリック
  146 |       if (piece && piece === piece.toLowerCase() && !piece.startsWith('+')) {
  147 |         console.log(`後手の駒を発見: ${piece}, 右クリックします`);
  148 |         
  149 |         await allPieces[i].click({ button: 'right' });
  150 |         await page.waitForTimeout(1500);
  151 |         
  152 |         // 右クリック後の持ち駒数を確認
  153 |         const afterBlackPieces = await page.locator('.pieces-in-hand').last().locator('.piece-container').count();
  154 |         const afterWhitePieces = await page.locator('.pieces-in-hand').first().locator('.piece-container').count();
  155 |         console.log('右クリック後 - 先手持ち駒:', afterBlackPieces, '後手持ち駒:', afterWhitePieces);
  156 |         
  157 |         const blackIncreased = afterBlackPieces > initialBlackPieces;
  158 |         const whiteIncreased = afterWhitePieces > initialWhitePieces;
  159 |         
  160 |         console.log('先手駒台に追加された:', blackIncreased);
  161 |         console.log('後手駒台に追加された:', whiteIncreased);
  162 |         
  163 |         // 後手の駒は後手の駒台に追加されるべき
  164 |         expect(whiteIncreased).toBe(true);
  165 |         expect(blackIncreased).toBe(false);
  166 |         
  167 |         break; // 1個目が見つかったら終了
  168 |       }
  169 |     }
  170 |   });
  171 | }); 
```