# Test info

- Name: 分岐管理機能テスト >> 分岐管理UIの基本表示確認
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\branch-management.spec.ts:42:3

# Error details

```
Error: Timed out 5000ms waiting for expect(locator).toBeVisible()

Locator: locator('.create-branch-btn')
Expected: visible
Received: <element(s) not found>
Call log:
  - expect.toBeVisible with timeout 5000ms
  - waiting for locator('.create-branch-btn')

    at C:\Users\kinoko\shogi_gui\frontend\tests\branch-management.spec.ts:48:54
```

# Page snapshot

```yaml
- banner: 対局モード 編集モード 検討モード
- button "局面コピー"
- text: "手数: 0 | 手番: 先手 検討中... 香 桂 銀 金 玉 金 銀 桂 香 飛 角 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 角 飛 香 桂 銀 金 王 金 銀 桂 香"
- heading "棋譜" [level=3]
- heading "分岐管理" [level=4]
- button "🌳 ツリー表示"
- text: main メイン
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
   3 | test.describe('分岐管理機能テスト', () => {
   4 |   test.beforeEach(async ({ page }) => {
   5 |     // アプリのトップページに移動
   6 |     await page.goto('/');
   7 |     
   8 |     // ページが読み込まれるまで待機
   9 |     await page.waitForSelector('#app');
   10 |     await page.waitForTimeout(1000);
   11 |     
   12 |     // ヘッダーが表示されるまで待機
   13 |     await page.waitForSelector('header', { timeout: 5000 });
   14 |     
   15 |     console.log('検討モードタブをクリックします...');
   16 |     // 検討モードタブをクリック
   17 |     const studyModeTab = page.locator('.tab').filter({ hasText: '検討モード' });
   18 |     await expect(studyModeTab).toBeVisible();
   19 |     await studyModeTab.click();
   20 |     
   21 |     // 対局開始ボタンをクリックしてゲームを開始
   22 |     console.log('対局開始ボタンをクリックします...');
   23 |     await page.click('button:has-text("対局開始")');
   24 |     await page.waitForTimeout(2000);
   25 |     
   26 |     // ページのHTMLを取得してデバッグ
   27 |     const pageContent = await page.content();
   28 |     console.log('ページ読み込み完了。分岐管理UI確認中...');
   29 |     
   30 |     // 分岐管理UIが表示されるまで待機
   31 |     try {
   32 |       await page.waitForSelector('.branch-manager', { timeout: 10000 });
   33 |       console.log('分岐管理UIが見つかりました');
   34 |     } catch (error) {
   35 |       console.error('分岐管理UIが見つかりませんでした:', error);
   36 |       // 現在表示されている要素をログ出力
   37 |       const visibleElements = await page.locator('*').allTextContents();
   38 |       console.log('表示されている要素:', visibleElements.slice(0, 10));
   39 |     }
   40 |   });
   41 |
   42 |   test('分岐管理UIの基本表示確認', async ({ page }) => {
   43 |     console.log('分岐管理UIの基本表示確認テスト開始...');
   44 |     
   45 |     // 分岐管理UIが表示されることを確認
   46 |     await expect(page.locator('.branch-manager')).toBeVisible({ timeout: 5000 });
   47 |     await expect(page.locator('.branch-header')).toBeVisible({ timeout: 5000 });
>  48 |     await expect(page.locator('.create-branch-btn')).toBeVisible({ timeout: 5000 });
      |                                                      ^ Error: Timed out 5000ms waiting for expect(locator).toBeVisible()
   49 |     
   50 |     // 初期状態で「main」分岐が表示されることを確認
   51 |     await expect(page.locator('.branch-item').filter({ hasText: 'main' })).toBeVisible({ timeout: 5000 });
   52 |     await expect(page.locator('.main-badge')).toBeVisible({ timeout: 5000 });
   53 |   });
   54 |
   55 |   test('分岐作成機能のテスト', async ({ page }) => {
   56 |     console.log('分岐作成機能テスト開始...');
   57 |     
   58 |     // 分岐作成ボタンをクリック
   59 |     await page.click('.create-branch-btn');
   60 |     
   61 |     // 分岐作成ダイアログが表示されることを確認
   62 |     await expect(page.locator('.dialog-overlay')).toBeVisible({ timeout: 5000 });
   63 |     await expect(page.locator('.dialog')).toBeVisible({ timeout: 5000 });
   64 |     await expect(page.locator('.dialog-header h5')).toHaveText('新しい分岐を作成');
   65 |     
   66 |     // 分岐名を入力
   67 |     const branchNameInput = page.locator('#branch-name');
   68 |     await branchNameInput.fill('test-branch');
   69 |     
   70 |     // 作成ボタンをクリック
   71 |     await page.click('.create-btn');
   72 |     
   73 |     // ダイアログが閉じることを確認
   74 |     await expect(page.locator('.dialog-overlay')).not.toBeVisible({ timeout: 5000 });
   75 |     
   76 |     // 新しい分岐が一覧に表示されることを確認
   77 |     await expect(page.locator('.branch-item').filter({ hasText: 'test-branch' })).toBeVisible({ timeout: 10000 });
   78 |   });
   79 |
   80 |   test('分岐切り替え機能のテスト', async ({ page }) => {
   81 |     console.log('分岐切り替え機能テスト開始...');
   82 |     
   83 |     // まず分岐を作成
   84 |     await page.click('.create-branch-btn');
   85 |     await page.fill('#branch-name', 'switch-test-branch');
   86 |     await page.click('.create-btn');
   87 |     
   88 |     // 分岐一覧で作成した分岐が表示されることを確認
   89 |     const newBranch = page.locator('.branch-item').filter({ hasText: 'switch-test-branch' });
   90 |     await expect(newBranch).toBeVisible();
   91 |     
   92 |     // main分岐に戻る
   93 |     const mainBranch = page.locator('.branch-item').filter({ hasText: 'main' });
   94 |     await mainBranch.click();
   95 |     
   96 |     // main分岐がアクティブになることを確認
   97 |     await expect(mainBranch).toHaveClass(/active/);
   98 |     
   99 |     // 新しい分岐に切り替え
  100 |     await newBranch.click();
  101 |     
  102 |     // 新しい分岐がアクティブになることを確認
  103 |     await expect(newBranch).toHaveClass(/active/);
  104 |   });
  105 |
  106 |   test('分岐削除機能のテスト', async ({ page }) => {
  107 |     console.log('分岐削除機能テスト開始...');
  108 |     
  109 |     // 削除用の分岐を作成
  110 |     await page.click('.create-branch-btn');
  111 |     await page.fill('#branch-name', 'delete-test-branch');
  112 |     await page.click('.create-btn');
  113 |     
  114 |     // 作成した分岐が表示されることを確認
  115 |     const targetBranch = page.locator('.branch-item').filter({ hasText: 'delete-test-branch' });
  116 |     await expect(targetBranch).toBeVisible();
  117 |     
  118 |     // 削除ボタンをクリック
  119 |     await targetBranch.locator('.delete-btn').click();
  120 |     
  121 |     // 削除確認ダイアログが表示されることを確認
  122 |     await expect(page.locator('.dialog-overlay')).toBeVisible();
  123 |     await expect(page.locator('.dialog-header')).toHaveText('分岐削除の確認');
  124 |     
  125 |     // 削除を実行
  126 |     await page.click('.delete-btn-confirm');
  127 |     
  128 |     // ダイアログが閉じることを確認
  129 |     await expect(page.locator('.dialog-overlay')).not.toBeVisible();
  130 |     
  131 |     // 分岐が一覧から削除されることを確認
  132 |     await expect(targetBranch).not.toBeVisible();
  133 |   });
  134 |
  135 |   test('main分岐の削除が禁止されることを確認', async ({ page }) => {
  136 |     console.log('main分岐削除禁止テスト開始...');
  137 |     
  138 |     // main分岐には削除ボタンが表示されないことを確認
  139 |     const mainBranch = page.locator('.branch-item').filter({ hasText: 'main' });
  140 |     await expect(mainBranch.locator('.delete-btn')).not.toBeVisible();
  141 |   });
  142 |
  143 |   test('無効な分岐名のバリデーションテスト', async ({ page }) => {
  144 |     console.log('分岐名バリデーションテスト開始...');
  145 |     
  146 |     // 分岐作成ダイアログを開く
  147 |     await page.click('.create-branch-btn');
  148 |     
```