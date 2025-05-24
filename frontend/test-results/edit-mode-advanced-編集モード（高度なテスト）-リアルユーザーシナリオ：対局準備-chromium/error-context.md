# Test info

- Name: 編集モード（高度なテスト） >> リアルユーザーシナリオ：対局準備
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\edit-mode-advanced.spec.ts:158:3

# Error details

```
Error: Timed out 5000ms waiting for expect(locator).toContainText(expected)

Locator: locator('.current-side')
Expected string: "先手"
Received string: " 現在: 後手"
Call log:
  - expect.toContainText with timeout 5000ms
  - waiting for locator('.current-side')
    9 × locator resolved to <div data-v-79c75a13="" class="current-side"> 現在: 後手</div>
      - unexpected value " 現在: 後手"

    at C:\Users\kinoko\shogi_gui\frontend\tests\edit-mode-advanced.spec.ts:180:49
```

# Page snapshot

```yaml
- banner: 対局モード 編集モード 検討モード
- text: "現在: 後手"
- button "手番切り替え"
- button "保存"
- text: "ゲームID: 2092 香 桂 銀 金 玉 金 銀 桂 香 飛 角 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 角 飛 香 桂 銀 金 王 金 銀 桂 香"
- paragraph: "右クリック: 盤上の駒を持ち駒に戻す"
- paragraph: "クリック: 駒の状態変更（成り不成反転 ↔ 向き反転を繰り返し）"
- paragraph: "持ち駒クリック→マスクリック: 持ち駒を盤上に配置"
```

# Test source

```ts
   80 |         }
   81 |         
   82 |         await page.waitForTimeout(100); // 短い間隔
   83 |       }
   84 |       
   85 |       // 10回ごとに手番切り替え
   86 |       if (i % 10 === 0) {
   87 |         await page.click('.toggle-side-btn');
   88 |         await page.waitForTimeout(100);
   89 |       }
   90 |     }
   91 |
   92 |     const endTime = Date.now();
   93 |     const duration = endTime - startTime;
   94 |     
   95 |     console.log(`Mass operation test completed in ${duration}ms (50 operations)`);
   96 |     expect(duration).toBeLessThan(30000); // 30秒以内に完了
   97 |     
   98 |     console.log('✅ Mass operation endurance test completed');
   99 |   });
  100 |
  101 |   test('データ整合性確認テスト', async ({ page }) => {
  102 |     console.log('Starting data consistency test...');
  103 |     
  104 |     // 操作前の状態を記録
  105 |     const initialPieceCount = await page.locator('.shogi-cell').filter({
  106 |       has: page.locator('.piece-shape[data-piece]')
  107 |     }).count();
  108 |     
  109 |     console.log('Initial pieces on board:', initialPieceCount);
  110 |     
  111 |     // 複数の駒を持ち駒に移動
  112 |     const pieces = page.locator('.shogi-cell').filter({
  113 |       has: page.locator('.piece-shape[data-piece]')
  114 |     });
  115 |     
  116 |     const moveCount = Math.min(5, await pieces.count());
  117 |     for (let i = 0; i < moveCount; i++) {
  118 |       await pieces.nth(i).click({ button: 'right' });
  119 |       await page.waitForTimeout(800);
  120 |     }
  121 |     
  122 |     // 持ち駒から盤上に戻す操作
  123 |     const handPieces = page.locator('.pieces-in-hand .piece-container');
  124 |     const handPieceCount = await handPieces.count();
  125 |     console.log('Hand pieces after moves:', handPieceCount);
  126 |     
  127 |     // 半分の持ち駒を盤上に戻す
  128 |     const returnCount = Math.min(3, handPieceCount);
  129 |     for (let i = 0; i < returnCount; i++) {
  130 |       await handPieces.nth(i).click();
  131 |       await page.waitForTimeout(500);
  132 |       
  133 |       // 空のマスに配置
  134 |       const emptyCell = page.locator('.shogi-cell').filter({
  135 |         hasNot: page.locator('.piece-shape')
  136 |       }).first();
  137 |       
  138 |       if (await emptyCell.count() > 0) {
  139 |         await emptyCell.click();
  140 |         await page.waitForTimeout(800);
  141 |       }
  142 |     }
  143 |     
  144 |     // 最終的な盤面の駒数を確認
  145 |     const finalPieceCount = await page.locator('.shogi-cell').filter({
  146 |       has: page.locator('.piece-shape[data-piece]')
  147 |     }).count();
  148 |     
  149 |     console.log('Final pieces on board:', finalPieceCount);
  150 |     
  151 |     // データ整合性の基本チェック（駒の総数が大きく変わっていないこと）
  152 |     const diff = Math.abs(finalPieceCount - initialPieceCount);
  153 |     expect(diff).toBeLessThan(10); // 大幅な変化がないことを確認
  154 |     
  155 |     console.log('✅ Data consistency test completed');
  156 |   });
  157 |
  158 |   test('リアルユーザーシナリオ：対局準備', async ({ page }) => {
  159 |     console.log('Starting real user scenario: game preparation...');
  160 |     
  161 |     // シナリオ：ユーザーが特定の局面を再現したい場合
  162 |     
  163 |     // 1. 手番を後手に変更
  164 |     await page.click('.toggle-side-btn');
  165 |     await expect(page.locator('.current-side')).toContainText('後手');
  166 |     
  167 |     // 2. 特定の駒を取り除く（飛車を移動してみる）
  168 |     const rookCell = page.locator('.shogi-cell').filter({
  169 |       has: page.locator('.piece-shape[data-piece="r"]')
  170 |     }).first();
  171 |     
  172 |     if (await rookCell.count() > 0) {
  173 |       console.log('Found rook, moving to hand...');
  174 |       await rookCell.click({ button: 'right' });
  175 |       await page.waitForTimeout(1500);
  176 |     }
  177 |     
  178 |     // 3. 手番を先手に戻す
  179 |     await page.click('.toggle-side-btn');
> 180 |     await expect(page.locator('.current-side')).toContainText('先手');
      |                                                 ^ Error: Timed out 5000ms waiting for expect(locator).toContainText(expected)
  181 |     
  182 |     // 4. 先手の歩を前進（ドラッグ&ドロップで）
  183 |     const pawnCell = page.locator('.shogi-cell').filter({
  184 |       has: page.locator('.piece-shape[data-piece="P"]')
  185 |     }).first();
  186 |     
  187 |     if (await pawnCell.count() > 0) {
  188 |       const targetCell = page.locator('.shogi-cell').filter({
  189 |         hasNot: page.locator('.piece-shape')
  190 |       }).nth(2); // 3番目の空マス
  191 |       
  192 |       if (await targetCell.count() > 0) {
  193 |         console.log('Moving pawn forward...');
  194 |         await pawnCell.locator('.piece-shape').dragTo(targetCell);
  195 |         await page.waitForTimeout(2000);
  196 |       }
  197 |     }
  198 |     
  199 |     // 5. 操作履歴の確認（unsavedChangesフラグ）
  200 |     const hasChanges = await page.evaluate(() => {
  201 |       const stores = (window as any).__PINIA__?._s;
  202 |       if (stores) {
  203 |         for (const [key, store] of stores.entries()) {
  204 |           if (key.includes('boardEdit') || key.includes('board')) {
  205 |             return store.unsavedChanges || false;
  206 |           }
  207 |         }
  208 |       }
  209 |       return false;
  210 |     });
  211 |     
  212 |     console.log('Has unsaved changes:', hasChanges);
  213 |     
  214 |     console.log('✅ Real user scenario test completed');
  215 |   });
  216 |
  217 |     test('ネットワーク断線シミュレーション', async ({ page }) => {
  218 |     console.log('Starting network disconnection simulation...');
  219 |     
  220 |     // ネットワークをオフラインに設定
  221 |     await page.context().setOffline(true);
  222 |     
  223 |     // オフライン状態でも編集操作が継続できることを確認
  224 |     const pieces = page.locator('.shogi-cell').filter({
  225 |       has: page.locator('.piece-shape[data-piece]')
  226 |     });
  227 |     
  228 |     const pieceCount = await pieces.count();
  229 |     if (pieceCount > 0) {
  230 |       // オフライン状態での操作
  231 |       await pieces.first().click();
  232 |       await page.waitForTimeout(1000);
  233 |       
  234 |       await pieces.nth(1).click({ button: 'right' });
  235 |       await page.waitForTimeout(1000);
  236 |       
  237 |       // 手番切り替え
  238 |       await page.click('.toggle-side-btn');
  239 |       await page.waitForTimeout(500);
  240 |     }
  241 |     
  242 |     // 保存ボタンの状態確認（オフライン時）
  243 |     const saveButton = page.locator('.save-btn');
  244 |     const isDisabled = await saveButton.isDisabled();
  245 |     console.log('Save button disabled in offline mode:', isDisabled);
  246 |     
  247 |     // ネットワークを復旧
  248 |     await page.context().setOffline(false);
  249 |     await page.waitForTimeout(1000);
  250 |     
  251 |     console.log('✅ Network disconnection simulation completed');
  252 |   });
  253 |
  254 |   test('キーボードショートカット操作テスト', async ({ page }) => {
  255 |     console.log('Starting keyboard shortcut test...');
  256 |     
  257 |     // フォーカスを盤面に移動
  258 |     await page.locator('.shogi-board').click();
  259 |     
  260 |     // キーボード操作のテスト
  261 |     
  262 |     // Spaceキーで手番切り替え（実装されている場合）
  263 |     await page.keyboard.press('Space');
  264 |     await page.waitForTimeout(500);
  265 |     
  266 |     // Tabキーでナビゲーション
  267 |     await page.keyboard.press('Tab');
  268 |     await page.waitForTimeout(300);
  269 |     await page.keyboard.press('Tab');
  270 |     await page.waitForTimeout(300);
  271 |     
  272 |     // Enterキーでボタンアクティベーション
  273 |     await page.keyboard.press('Enter');
  274 |     await page.waitForTimeout(500);
  275 |     
  276 |     // Escapeキーで選択解除（実装されている場合）
  277 |     await page.keyboard.press('Escape');
  278 |     await page.waitForTimeout(300);
  279 |     
  280 |     console.log('✅ Keyboard shortcut test completed');
```