# Test info

- Name: 分岐ツリーAPI機能テスト
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\tree-api-test.spec.ts:3:1

# Error details

```
Error: expect(received).toBeGreaterThan(expected)

Expected: > 0
Received:   0
    at C:\Users\kinoko\shogi_gui\frontend\tests\tree-api-test.spec.ts:64:28
```

# Page snapshot

```yaml
- banner: 対局モード 編集モード 検討モード
- button "対局開始"
- button "入玉宣言"
- button "投了"
- text: "手数: 0 | 手番: 先手 香 桂 銀 金 玉 金 銀 桂 香 飛 角 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 角 飛 香 桂 銀 金 王 金 銀 桂 香"
- heading "棋譜" [level=3]
- text: "分岐:"
- combobox "分岐:":
  - option "main" [selected]
  - option "main-1"
- button "|◀"
- button "◀"
- button "▶" [disabled]
- button "▶|" [disabled]
- text: 0. 開始局面 🌿 1 1. ▲7六歩 🌿 1
```

# Test source

```ts
   1 | import { test, expect } from '@playwright/test';
   2 |
   3 | test('分岐ツリーAPI機能テスト', async ({ page }) => {
   4 |   console.log('=== 分岐ツリーAPI機能テスト開始 ===');
   5 |   
   6 |   console.log('1. 既存のゲーム1876（分岐があることが確認済み）にアクセス...');
   7 |   await page.goto('http://localhost:5173?game_id=1876');
   8 |   await page.waitForTimeout(5000);
   9 |
  10 |   console.log('2. 分岐ツリー構造をAPIで取得...');
  11 |   const treeStructure = await page.evaluate(async () => {
  12 |     const response = await fetch('http://localhost:3000/api/v1/games/1876/board_histories/branch_tree');
  13 |     return await response.json();
  14 |   });
  15 |   console.log('🌳 分岐ツリー構造:', JSON.stringify(treeStructure, null, 2));
  16 |
  17 |   console.log('3. 手数0での分岐情報をAPIで取得...');
  18 |   const branchesAtMove0 = await page.evaluate(async () => {
  19 |     const response = await fetch('http://localhost:3000/api/v1/games/1876/board_histories/branches_at_move/0');
  20 |     return await response.json();
  21 |   });
  22 |   console.log('📊 手数0の分岐情報:', branchesAtMove0);
  23 |
  24 |   console.log('4. 手数1での分岐情報をAPIで取得...');
  25 |   const branchesAtMove1 = await page.evaluate(async () => {
  26 |     const response = await fetch('http://localhost:3000/api/v1/games/1876/board_histories/branches_at_move/1');
  27 |     return await response.json();
  28 |   });
  29 |   console.log('📊 手数1の分岐情報:', branchesAtMove1);
  30 |
  31 |   console.log('5. UI上で分岐インジケータを確認...');
  32 |   await page.waitForSelector('.move-history-panel', { timeout: 10000 });
  33 |
  34 |   // 分岐インジケータの数を確認
  35 |   const branchIndicators = await page.locator('.branch-indicator').count();
  36 |   console.log(`UIでの分岐インジケータ数: ${branchIndicators}`);
  37 |
  38 |   // 分岐インジケータの詳細を取得
  39 |   const indicatorDetails = await page.locator('.branch-indicator').all();
  40 |   const details = [];
  41 |   for (let i = 0; i < indicatorDetails.length; i++) {
  42 |     const indicator = indicatorDetails[i];
  43 |     const isVisible = await indicator.isVisible();
  44 |     const countText = await indicator.locator('.branch-count').textContent();
  45 |     details.push({ index: i, text: countText, visible: isVisible });
  46 |   }
  47 |   console.log('分岐インジケータの詳細:', details);
  48 |
  49 |   // API結果の検証
  50 |   console.log('6. API結果の検証...');
  51 |   expect(treeStructure).toBeDefined();
  52 |   expect(treeStructure.total_branches).toBeGreaterThan(1);
  53 |   console.log(`✅ 分岐総数: ${treeStructure.total_branches}`);
  54 |
  55 |   expect(branchesAtMove0).toBeDefined();
  56 |   expect(branchesAtMove0.branch_count).toBeGreaterThan(1);
  57 |   console.log(`✅ 手数0の分岐数: ${branchesAtMove0.branch_count}`);
  58 |
  59 |   expect(branchesAtMove1).toBeDefined();
  60 |   expect(branchesAtMove1.branch_count).toBeGreaterThan(1);
  61 |   console.log(`✅ 手数1の分岐数: ${branchesAtMove1.branch_count}`);
  62 |
  63 |   // UI検証
> 64 |   expect(branchIndicators).toBeGreaterThan(0);
     |                            ^ Error: expect(received).toBeGreaterThan(expected)
  65 |   console.log(`✅ UI分岐インジケータ数: ${branchIndicators}`);
  66 |
  67 |   console.log('=== 分岐ツリーAPI機能テスト完了 ===');
  68 | }); 
```