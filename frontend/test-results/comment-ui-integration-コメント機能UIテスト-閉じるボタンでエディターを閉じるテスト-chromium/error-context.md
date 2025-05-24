# Test info

- Name: コメント機能UIテスト >> 閉じるボタンでエディターを閉じるテスト
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:133:3

# Error details

```
Error: page.waitForSelector: Test timeout of 30000ms exceeded.
Call log:
  - waiting for locator('#app') to be visible
    63 × locator resolved to hidden <div id="app"></div>

    at C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:7:16
```

# Page snapshot

```yaml
- text: "[vue/compiler-sfc] Unexpected token, expected \";\" (2:38) /app/src/components/BranchNode.vue 38 | 39 | <script setup lang=\"ts\"> 40 | interface TreeNode { branch: string move_number?: number move_notation?: string display_name?: string parent_branch?: string | null branch_point?: number | null depth: number children: TreeNode[] sfen?: string} | ^ 41 | 42 | interface Props { at constructor (/app/node_modules/@babel/parser/lib/index.js:360:19) at TypeScriptParserMixin.raise (/app/node_modules/@babel/parser/lib/index.js:6613:19) at TypeScriptParserMixin.unexpected (/app/node_modules/@babel/parser/lib/index.js:6633:16) at TypeScriptParserMixin.expect (/app/node_modules/@babel/parser/lib/index.js:6914:12) at TypeScriptParserMixin.tsParseTypeMemberSemicolon (/app/node_modules/@babel/parser/lib/index.js:8086:12) at TypeScriptParserMixin.tsParsePropertyOrMethodSignature (/app/node_modules/@babel/parser/lib/index.js:8165:12) at TypeScriptParserMixin.tsParseTypeMember (/app/node_modules/@babel/parser/lib/index.js:8200:17) at TypeScriptParserMixin.tsParseList (/app/node_modules/@babel/parser/lib/index.js:7846:19) at TypeScriptParserMixin.tsParseObjectTypeMembers (/app/node_modules/@babel/parser/lib/index.js:8209:26) at TypeScriptParserMixin.tsInType (/app/node_modules/@babel/parser/lib/index.js:8782:14 Click outside, press Esc key, or fix the code to dismiss. You can also disable this overlay by setting"
- code: server.hmr.overlay
- text: to
- code: "false"
- text: in
- code: vite.config.ts
- text: .
```

# Test source

```ts
   1 | import { test, expect } from '@playwright/test';
   2 |
   3 | test.describe('コメント機能UIテスト', () => {
   4 |   test.beforeEach(async ({ page }) => {
   5 |     // アプリケーションにアクセス
   6 |     await page.goto('http://localhost:5173/');
>  7 |     await page.waitForSelector('#app');
     |                ^ Error: page.waitForSelector: Test timeout of 30000ms exceeded.
   8 |     await page.waitForTimeout(2000);
   9 |   });
   10 |
   11 |   test('アプリケーションの基本動作確認', async ({ page }) => {
   12 |     console.log('=== アプリケーション基本動作確認 ===');
   13 |     
   14 |     // ページが読み込まれることを確認
   15 |     const title = await page.title();
   16 |     console.log(`✅ ページタイトル: ${title}`);
   17 |     
   18 |     // メニューバーが表示されることを確認
   19 |     const menuBar = page.locator('header');
   20 |     await expect(menuBar).toBeVisible();
   21 |     console.log('✅ メニューバーが表示されています');
   22 |     
   23 |     // 検討モードタブが存在することを確認
   24 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
   25 |     if (await studyTab.count() > 0) {
   26 |       await expect(studyTab).toBeVisible();
   27 |       console.log('✅ 検討モードタブが表示されています');
   28 |       
   29 |       // 検討モードに切り替え
   30 |       await studyTab.click();
   31 |       await page.waitForTimeout(1000);
   32 |       console.log('✅ 検討モードに切り替えました');
   33 |     } else {
   34 |       console.log('⚠️ 検討モードタブが見つかりませんでした');
   35 |     }
   36 |   });
   37 |
   38 |   test('コメント追加と画面閉じる動作テスト', async ({ page }) => {
   39 |     console.log('=== コメント追加と画面閉じる動作テスト ===');
   40 |     
   41 |     // 検討モードに切り替え
   42 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
   43 |     if (await studyTab.count() > 0) {
   44 |       await studyTab.click();
   45 |       await page.waitForTimeout(2000);
   46 |       console.log('✅ 検討モードに切り替えました');
   47 |       
   48 |       // コメントボタンが存在するかを確認
   49 |       const commentButtons = page.locator('.comment-toggle-btn').first();
   50 |       if (await commentButtons.count() > 0) {
   51 |         console.log('✅ コメントボタンが見つかりました');
   52 |         
   53 |         // コメントエディターを開く
   54 |         await commentButtons.click();
   55 |         await page.waitForTimeout(1000);
   56 |         
   57 |         // エディターパネルが表示されることを確認
   58 |         const editorPanel = page.locator('.comment-editor-panel');
   59 |         await expect(editorPanel).toBeVisible();
   60 |         console.log('✅ コメントエディターパネルが開きました');
   61 |         
   62 |         // 「+ コメントを追加」ボタンをクリック
   63 |         const addButton = page.locator('.add-comment-btn');
   64 |         if (await addButton.count() > 0) {
   65 |           await addButton.click();
   66 |           await page.waitForTimeout(500);
   67 |           console.log('✅ コメント追加ボタンをクリックしました');
   68 |           
   69 |           // テキストエリアが表示されることを確認
   70 |           const textarea = page.locator('.comment-textarea');
   71 |           await expect(textarea).toBeVisible();
   72 |           console.log('✅ テキストエリアが表示されました');
   73 |           
   74 |           // コメントを入力
   75 |           await textarea.fill('テストコメントです');
   76 |           console.log('✅ コメントを入力しました');
   77 |           
   78 |           // 作成ボタンをクリック
   79 |           const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
   80 |           await createButton.click();
   81 |           console.log('✅ 作成ボタンをクリックしました');
   82 |           
   83 |           // 成功メッセージが表示されることを確認
   84 |           const successMessage = page.locator('.success-message');
   85 |           await expect(successMessage).toBeVisible();
   86 |           console.log('✅ 成功メッセージが表示されました');
   87 |           
   88 |           // パネルが自動的に閉じることを確認（1.5秒待機）
   89 |           await page.waitForTimeout(2000);
   90 |           await expect(editorPanel).not.toBeVisible();
   91 |           console.log('✅ エディターパネルが自動的に閉じました');
   92 |           
   93 |         } else {
   94 |           console.log('⚠️ コメント追加ボタンが見つかりませんでした');
   95 |         }
   96 |       } else {
   97 |         console.log('⚠️ コメントボタンが見つかりませんでした');
   98 |       }
   99 |     }
  100 |   });
  101 |
  102 |   test('ESCキーでエディターを閉じるテスト', async ({ page }) => {
  103 |     console.log('=== ESCキーでエディターを閉じるテスト ===');
  104 |     
  105 |     // 検討モードに切り替え
  106 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  107 |     if (await studyTab.count() > 0) {
```