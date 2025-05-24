# Test info

- Name: 編集モード >> 手番切り替えボタンが正常に動作する
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\edit-mode-simple.spec.ts:38:3

# Error details

```
Error: Timed out 5000ms waiting for expect(locator).toContainText(expected)

Locator: locator('.current-side')
Expected string: "現在: 先手"
Received string: " 現在: 後手"
Call log:
  - expect.toContainText with timeout 5000ms
  - waiting for locator('.current-side')
    8 × locator resolved to <div data-v-79c75a13="" class="current-side"> 現在: 後手</div>
      - unexpected value " 現在: 後手"

    at C:\Users\kinoko\shogi_gui\frontend\tests\edit-mode-simple.spec.ts:50:49
```

# Page snapshot

```yaml
- banner: 対局モード 編集モード 検討モード
- text: "現在: 後手"
- button "手番切り替え"
- button "保存"
- text: "ゲームID: 2124 香 桂 銀 金 玉 金 銀 桂 香 飛 角 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 角 飛 香 桂 銀 金 王 金 銀 桂 香"
- paragraph: "右クリック: 盤上の駒を持ち駒に戻す"
- paragraph: "クリック: 駒の状態変更（成り不成反転 ↔ 向き反転を繰り返し）"
- paragraph: "持ち駒クリック→マスクリック: 持ち駒を盤上に配置"
```

# Test source

```ts
   1 | import { test, expect } from '@playwright/test';
   2 |
   3 | test.describe('編集モード', () => {
   4 |   test.beforeEach(async ({ page }) => {
   5 |     // アプリのトップページに移動
   6 |     await page.goto('/');
   7 |     
   8 |     // ページが読み込まれるまで待機
   9 |     await page.waitForSelector('#app');
  10 |     
  11 |     // 少し待ってからMenuBarを探す
  12 |     await page.waitForTimeout(2000);
  13 |     
  14 |     // MenuBarが存在することを確認
  15 |     await page.waitForSelector('header', { timeout: 5000 });
  16 |     
  17 |     // 編集モードタブをクリック
  18 |     const editModeTab = page.locator('.tab').filter({ hasText: '編集モード' });
  19 |     await expect(editModeTab).toBeVisible();
  20 |     await editModeTab.click();
  21 |     
  22 |     // EditBoardが表示されるまで待機
  23 |     await page.waitForSelector('.edit-board-container', { timeout: 10000 });
  24 |   });
  25 |
  26 |   test('編集モードの基本UI要素が表示される', async ({ page }) => {
  27 |     // 基本的なUI要素の存在確認
  28 |     await expect(page.locator('.board-controls')).toBeVisible();
  29 |     await expect(page.locator('.current-side')).toBeVisible();
  30 |     await expect(page.locator('.toggle-side-btn')).toBeVisible();
  31 |     await expect(page.locator('.save-btn')).toBeVisible();
  32 |     await expect(page.locator('.shogi-board')).toBeVisible();
  33 |     // 持ち駒エリアが2つ存在することを確認（先手・後手）
  34 |     await expect(page.locator('.pieces-in-hand').first()).toBeVisible();
  35 |     await expect(page.locator('.pieces-in-hand').last()).toBeVisible();
  36 |   });
  37 |
  38 |   test('手番切り替えボタンが正常に動作する', async ({ page }) => {
  39 |     // 初期状態（先手）を確認
  40 |     await expect(page.locator('.current-side')).toContainText('現在: 先手');
  41 |     
  42 |     // 手番切り替えボタンをクリック
  43 |     await page.click('.toggle-side-btn');
  44 |     
  45 |     // 後手に変わることを確認
  46 |     await expect(page.locator('.current-side')).toContainText('現在: 後手');
  47 |     
  48 |     // もう一度クリックして先手に戻ることを確認
  49 |     await page.click('.toggle-side-btn');
> 50 |     await expect(page.locator('.current-side')).toContainText('現在: 先手');
     |                                                 ^ Error: Timed out 5000ms waiting for expect(locator).toContainText(expected)
  51 |   });
  52 |
  53 |   test('右クリックで駒を持ち駒に移動できる', async ({ page }) => {
  54 |     // コンソールログを監視
  55 |     page.on('console', msg => {
  56 |       console.log('Browser console:', msg.text());
  57 |     });
  58 |     
  59 |     // 初期の持ち駒数を確認
  60 |     const initialHandPieceCount = await page.locator('.pieces-in-hand .piece-container').count();
  61 |     console.log('Initial hand piece count:', initialHandPieceCount);
  62 |     
  63 |     // 盤上の駒を右クリック
  64 |     const pieceCell = page.locator('.shogi-cell').filter({
  65 |       has: page.locator('.piece-shape[data-piece]')
  66 |     }).first();
  67 |     
  68 |     await expect(pieceCell).toBeVisible();
  69 |     
  70 |     // 駒の種類を記録
  71 |     const pieceType = await pieceCell.locator('.piece-shape').getAttribute('data-piece');
  72 |     const pieceOwner = await pieceCell.locator('.piece-shape').getAttribute('data-owner');
  73 |     console.log('Right-clicking piece:', pieceType, 'Owner:', pieceOwner);
  74 |     
  75 |     // 右クリックで駒を持ち駒に移動
  76 |     await pieceCell.click({ button: 'right' });
  77 |     await page.waitForTimeout(2000);
  78 |     
  79 |     // 持ち駒が増えたかチェック
  80 |     const afterRightClickCount = await page.locator('.pieces-in-hand .piece-container').count();
  81 |     console.log('After right click count:', afterRightClickCount);
  82 |     
  83 |     // 持ち駒エリアに駒が追加されることを確認
  84 |     expect(afterRightClickCount).toBeGreaterThan(initialHandPieceCount);
  85 |   });
  86 |
  87 |   test('保存ボタンの動作確認', async ({ page }) => {
  88 |     // 保存ボタンが存在することを確認
  89 |     const saveButton = page.locator('.save-btn');
  90 |     await expect(saveButton).toBeVisible();
  91 |     
  92 |     console.log('✅ Save button functionality verified');
  93 |   });
  94 | }); 
```