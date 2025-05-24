# Test info

- Name: コメント作成と表示の詳細テスト >> バックエンドへのリクエスト形式確認
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\comment-creation-validation.spec.ts:132:3

# Error details

```
Error: locator.click: Test timeout of 30000ms exceeded.
Call log:
  - waiting for locator('.tab').filter({ hasText: '検討モード' })
    - locator resolved to <div class="tab" data-v-476d183d=""> 検討モード </div>
  - attempting click action
    2 × waiting for element to be visible, enabled and stable
      - element is visible, enabled and stable
      - scrolling into view if needed
      - done scrolling
      - <vite-error-overlay></vite-error-overlay> intercepts pointer events
    - retrying click action
    - waiting 20ms
    2 × waiting for element to be visible, enabled and stable
      - element is visible, enabled and stable
      - scrolling into view if needed
      - done scrolling
      - <vite-error-overlay></vite-error-overlay> intercepts pointer events
    - retrying click action
      - waiting 100ms
    42 × waiting for element to be visible, enabled and stable
       - element is visible, enabled and stable
       - scrolling into view if needed
       - done scrolling
       - <vite-error-overlay></vite-error-overlay> intercepts pointer events
     - retrying click action
       - waiting 500ms

    at C:\Users\kinoko\shogi_gui\frontend\tests\comment-creation-validation.spec.ts:12:24
```

# Page snapshot

```yaml
- banner: 対局モード 編集モード 検討モード
- button "対局開始"
- button "入玉宣言"
- button "投了"
- text: "手数: 0 | 手番: 先手 香 桂 銀 金 玉 金 銀 桂 香 飛 角 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 角 飛 香 桂 銀 金 王 金 銀 桂 香"
- heading "棋譜" [level=3]
- button "|◀" [disabled]
- button "◀" [disabled]
- button "▶" [disabled]
- button "▶|" [disabled]
- text: "0. 開始局面 [vue/compiler-sfc] Unexpected token, expected \";\" (10:38) /app/src/components/BranchTreeViewer.vue 61 | } 62 | 63 | interface TreeNode { branch: string move_number?: number move_notation?: string display_name?: string parent_branch?: string | null branch_point?: number | null depth: number children: TreeNode[] sfen?: string} | ^ 64 | 65 | interface TreeData { at constructor (/app/node_modules/@babel/parser/lib/index.js:360:19) at TypeScriptParserMixin.raise (/app/node_modules/@babel/parser/lib/index.js:6613:19) at TypeScriptParserMixin.unexpected (/app/node_modules/@babel/parser/lib/index.js:6633:16) at TypeScriptParserMixin.expect (/app/node_modules/@babel/parser/lib/index.js:6914:12) at TypeScriptParserMixin.tsParseTypeMemberSemicolon (/app/node_modules/@babel/parser/lib/index.js:8086:12) at TypeScriptParserMixin.tsParsePropertyOrMethodSignature (/app/node_modules/@babel/parser/lib/index.js:8165:12) at TypeScriptParserMixin.tsParseTypeMember (/app/node_modules/@babel/parser/lib/index.js:8200:17) at TypeScriptParserMixin.tsParseList (/app/node_modules/@babel/parser/lib/index.js:7846:19) at TypeScriptParserMixin.tsParseObjectTypeMembers (/app/node_modules/@babel/parser/lib/index.js:8209:26) at TypeScriptParserMixin.tsInType (/app/node_modules/@babel/parser/lib/index.js:8782:14 Click outside, press Esc key, or fix the code to dismiss. You can also disable this overlay by setting"
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
   3 | test.describe('コメント作成と表示の詳細テスト', () => {
   4 |   test.beforeEach(async ({ page }) => {
   5 |     await page.goto('/');
   6 |     await page.waitForSelector('#app');
   7 |     await page.waitForTimeout(2000);
   8 |     await page.waitForSelector('header', { timeout: 5000 });
   9 |     
   10 |     const studyModeTab = page.locator('.tab').filter({ hasText: '検討モード' });
   11 |     await expect(studyModeTab).toBeVisible();
>  12 |     await studyModeTab.click();
      |                        ^ Error: locator.click: Test timeout of 30000ms exceeded.
   13 |     
   14 |     await page.waitForSelector('.wrapper', { timeout: 10000 });
   15 |     await page.waitForTimeout(1000);
   16 |   });
   17 |
   18 |   test('コメント作成後に表示されることを確認', async ({ page }) => {
   19 |     console.log('=== コメント作成・表示テスト開始 ===');
   20 |     
   21 |     // API通信を監視
   22 |     let createRequestMade = false;
   23 |     let createResponseStatus = 0;
   24 |     let createResponseBody = '';
   25 |     
   26 |     page.on('response', async response => {
   27 |       if (response.url().includes('/api/v1/games/') && response.url().includes('/comments') && response.request().method() === 'POST') {
   28 |         createRequestMade = true;
   29 |         createResponseStatus = response.status();
   30 |         try {
   31 |           createResponseBody = await response.text();
   32 |           console.log(`コメント作成 API Response: ${createResponseStatus} - ${createResponseBody}`);
   33 |           
   34 |           // エラーレスポンスの詳細を表示
   35 |           if (createResponseStatus >= 400) {
   36 |             try {
   37 |               const errorData = JSON.parse(createResponseBody);
   38 |               console.log(`エラー詳細: ${JSON.stringify(errorData, null, 2)}`);
   39 |             } catch (parseError) {
   40 |               console.log(`エラーレスポンスのパースに失敗: ${parseError}`);
   41 |             }
   42 |           }
   43 |         } catch (e) {
   44 |           console.log(`API Response parsing failed: ${e}`);
   45 |         }
   46 |       }
   47 |     });
   48 |
   49 |     page.on('request', request => {
   50 |       if (request.url().includes('/api/v1/games/') && request.url().includes('/comments') && request.method() === 'POST') {
   51 |         console.log(`コメント作成 API Request: ${request.method()} ${request.url()}`);
   52 |         console.log(`Request Body: ${request.postData()}`);
   53 |       }
   54 |     });
   55 |     
   56 |     const firstMoveItem = page.locator('.move-item').first();
   57 |     await expect(firstMoveItem).toBeVisible();
   58 |     
   59 |     const commentToggleBtn = firstMoveItem.locator('.comment-toggle-btn').first();
   60 |     await expect(commentToggleBtn).toBeVisible();
   61 |     
   62 |     // コメントエディターを開く
   63 |     await commentToggleBtn.click();
   64 |     await page.waitForTimeout(1000);
   65 |     
   66 |     // コメント追加ボタンをクリック
   67 |     const addCommentBtn = page.locator('button').filter({ hasText: '+ コメントを追加' });
   68 |     await expect(addCommentBtn).toBeVisible();
   69 |     await addCommentBtn.click();
   70 |     await page.waitForTimeout(500);
   71 |     
   72 |     // テキストエリアが表示されることを確認
   73 |     const textarea = page.locator('.comment-textarea');
   74 |     await expect(textarea).toBeVisible();
   75 |     
   76 |     // テストコメントを入力
   77 |     const testComment = 'テスト用コメント - ' + Date.now();
   78 |     await textarea.fill(testComment);
   79 |     await page.waitForTimeout(500);
   80 |     
   81 |     // 作成ボタンをクリック
   82 |     const createBtn = page.locator('.save-btn').filter({ hasText: '作成' });
   83 |     await expect(createBtn).toBeVisible();
   84 |     await expect(createBtn).not.toBeDisabled();
   85 |     
   86 |     await createBtn.click();
   87 |     
   88 |     // API通信の完了を待つ
   89 |     await page.waitForTimeout(3000);
   90 |     
   91 |     // API呼び出しの確認
   92 |     console.log(`✅ 作成リクエスト送信: ${createRequestMade}`);
   93 |     console.log(`✅ レスポンスステータス: ${createResponseStatus}`);
   94 |     
   95 |     if (createRequestMade) {
   96 |       if (createResponseStatus === 201) {
   97 |         console.log('✅ コメント作成APIが成功しました');
   98 |         
   99 |         // 作成されたコメントが表示されるかを確認
  100 |         const commentDisplays = page.locator('.comment-display');
  101 |         if (await commentDisplays.count() > 0) {
  102 |           console.log('✅ コメント表示エリアが見つかりました');
  103 |           
  104 |           // テストコメントの内容が表示されているかを確認
  105 |           const commentContents = page.locator('.comment-content');
  106 |           let foundTestComment = false;
  107 |           
  108 |           for (let i = 0; i < await commentContents.count(); i++) {
  109 |             const content = await commentContents.nth(i).textContent();
  110 |             if (content && content.includes('テスト用コメント')) {
  111 |               foundTestComment = true;
  112 |               console.log(`✅ 作成したコメントが表示されています: "${content}"`);
```