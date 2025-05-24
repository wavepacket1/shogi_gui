# Test info

- Name: 分岐ツリー表示機能テスト
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\tree-viewer-test.spec.ts:3:1

# Error details

```
TimeoutError: page.waitForSelector: Timeout 10000ms exceeded.
Call log:
  - waiting for locator('.tree-container') to be visible

    at C:\Users\kinoko\shogi_gui\frontend\tests\tree-viewer-test.spec.ts:52:16
```

# Page snapshot

```yaml
- banner: 対局モード 編集モード 検討モード
- button "局面コピー"
- text: "手数: 0 | 手番: 先手 検討中... 香 桂 銀 金 玉 金 銀 桂 香 飛 角 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 角 飛 香 桂 銀 金 王 金 銀 桂 香"
- heading "棋譜" [level=3]
- button "🌳 分岐ツリー表示"
- heading "分岐ツリー構造" [level=4]
- button "×"
- text: "📊 総分岐数: 1 🌿 main 現在 手数から 深さ0"
- heading "📄 分岐詳細" [level=5]
- strong: "分岐名:"
- text: main
- strong: "指し手:"
- text: main
- strong: "深さ:"
- text: "0"
- button "|◀" [disabled]
- button "◀" [disabled]
- button "▶" [disabled]
- button "▶|" [disabled]
- text: 0. 開始局面
- button:
  - img
```

# Test source

```ts
   1 | import { test, expect } from '@playwright/test';
   2 |
   3 | test('分岐ツリー表示機能テスト', async ({ page }) => {
   4 |   console.log('=== 分岐ツリー表示機能テスト開始 ===');
   5 |   
   6 |   console.log('1. 分岐が存在するゲーム1876にstudyモードでアクセス...');
   7 |   await page.goto('http://localhost:5173?game_id=1876&mode=study');
   8 |   await page.waitForTimeout(5000);
   9 |
   10 |   console.log('2. MoveHistoryPanelが表示されるまで待機...');
   11 |   await page.waitForSelector('.move-history-panel', { timeout: 10000 });
   12 |
   13 |   console.log('3. BranchManagerが表示されることを確認...');
   14 |   await page.waitForSelector('.branch-manager', { timeout: 10000 });
   15 |   
   16 |   const branchManager = page.locator('.branch-manager');
   17 |   await expect(branchManager).toBeVisible();
   18 |   console.log('BranchManagerが正常に表示されました');
   19 |
   20 |   console.log('4. ツリー表示ボタンの存在確認...');
   21 |   const treeButton = page.locator('.tree-view-btn');
   22 |   await expect(treeButton).toBeVisible({ timeout: 5000 });
   23 |   
   24 |   const buttonText = await treeButton.textContent();
   25 |   console.log(`ツリー表示ボタンのテキスト: ${buttonText}`);
   26 |   expect(buttonText).toContain('ツリー表示');
   27 |
   28 |   console.log('5. ツリー表示ボタンをクリック...');
   29 |   await treeButton.click();
   30 |   await page.waitForTimeout(3000);
   31 |
   32 |   console.log('6. ツリービューアが表示されることを確認...');
   33 |   await page.waitForSelector('.branch-tree-viewer', { timeout: 10000 });
   34 |   
   35 |   const treeViewer = page.locator('.branch-tree-viewer');
   36 |   await expect(treeViewer).toBeVisible();
   37 |
   38 |   console.log('7. ツリーヘッダーの確認...');
   39 |   const header = page.locator('.tree-header h4');
   40 |   await expect(header).toHaveText('分岐ツリー構造');
   41 |
   42 |   console.log('8. ローディング状態から内容表示への変化を確認...');
   43 |   // ローディング状態の待機
   44 |   const loading = page.locator('.loading');
   45 |   if (await loading.isVisible()) {
   46 |     console.log('ローディング表示確認済み');
   47 |     // ローディングが消えるまで待機
   48 |     await page.waitForSelector('.tree-container', { timeout: 10000 });
   49 |     console.log('ツリーコンテナが表示されました');
   50 |   } else {
   51 |     console.log('ローディング表示をスキップ、直接コンテナを確認');
>  52 |     await page.waitForSelector('.tree-container', { timeout: 10000 });
      |                ^ TimeoutError: page.waitForSelector: Timeout 10000ms exceeded.
   53 |   }
   54 |
   55 |   console.log('9. ツリー統計の確認...');
   56 |   const treeStats = page.locator('.tree-stats .stat-item');
   57 |   await expect(treeStats).toBeVisible();
   58 |   
   59 |   const statsText = await treeStats.textContent();
   60 |   console.log(`ツリー統計: ${statsText}`);
   61 |   expect(statsText).toContain('総分岐数');
   62 |
   63 |   console.log('10. ツリー可視化エリアの確認...');
   64 |   const treeVisualization = page.locator('.tree-visualization');
   65 |   await expect(treeVisualization).toBeVisible();
   66 |
   67 |   console.log('11. 分岐ノードの確認...');
   68 |   const branchNodes = page.locator('.branch-node');
   69 |   const nodeCount = await branchNodes.count();
   70 |   console.log(`分岐ノード数: ${nodeCount}`);
   71 |   expect(nodeCount).toBeGreaterThan(0);
   72 |
   73 |   console.log('12. 指し手表示ノードの確認...');  const moveNodes = page.locator('.move-number');  if (await moveNodes.count() > 0) {    console.log('指し手表示が正常に動作しています');    const firstMoveText = await moveNodes.first().textContent();    console.log(`最初の指し手表示: ${firstMoveText}`);  }    const mainNode = page.locator('.node-item.main');  await expect(mainNode).toBeVisible();
   74 |
   75 |   console.log('13. 分岐詳細情報の確認...');
   76 |   const branchDetails = page.locator('.branch-details');
   77 |   await expect(branchDetails).toBeVisible();
   78 |
   79 |   console.log('14. 分岐ノードクリックでの詳細更新テスト...');
   80 |   const firstNode = branchNodes.first();
   81 |   await firstNode.click();
   82 |   await page.waitForTimeout(1000);
   83 |   
   84 |   // 詳細情報が更新されることを確認
   85 |   const detailItems = page.locator('.detail-item');
   86 |   const detailCount = await detailItems.count();
   87 |   console.log(`詳細項目数: ${detailCount}`);
   88 |   expect(detailCount).toBeGreaterThan(0);
   89 |
   90 |   console.log('15. ツリービューアの閉じるボタンテスト...');
   91 |   const closeButton = page.locator('.tree-header .close-btn');
   92 |   await expect(closeButton).toBeVisible();
   93 |   
   94 |   await closeButton.click();
   95 |   await page.waitForTimeout(1000);
   96 |
   97 |   console.log('16. ツリービューアが閉じられることを確認...');
   98 |   await expect(treeViewer).toBeHidden();
   99 |
  100 |   console.log('=== 分岐ツリー表示機能テスト完了 ===');
  101 | }); 
```