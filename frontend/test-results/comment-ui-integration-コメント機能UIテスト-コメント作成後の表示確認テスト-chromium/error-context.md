# Test info

- Name: コメント機能UIテスト >> コメント作成後の表示確認テスト
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:275:3

# Error details

```
Error: Timed out 5000ms waiting for expect(locator).toBeVisible()

Locator: locator('.comment-list')
Expected: visible
Received: <element(s) not found>
Call log:
  - expect.toBeVisible with timeout 5000ms
  - waiting for locator('.comment-list')

    at C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:329:37
```

# Page snapshot

```yaml
- banner: 対局モード 編集モード 検討モード
- button "局面コピー"
- text: "手数: 0 | 手番: 先手 検討中... 香 桂 銀 金 玉 金 銀 桂 香 飛 角 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 歩 角 飛 香 桂 銀 金 王 金 銀 桂 香"
- heading "棋譜" [level=3]
- button "🌳 分岐ツリー表示"
- button "|◀" [disabled]
- button "◀" [disabled]
- button "▶" [disabled]
- button "▶|" [disabled]
- text: 0. 開始局面
- button "1":
  - img
  - text: "1"
```

# Test source

```ts
  229 |         }
  230 |       } else {
  231 |         console.log('⚠️ コメントエディターが見つかりませんでした');
  232 |       }
  233 |     }
  234 |   });
  235 |
  236 |   test('ネットワーク接続の確認', async ({ page }) => {
  237 |     console.log('=== ネットワーク接続確認 ===');
  238 |     
  239 |     let apiRequestCount = 0;
  240 |     let successCount = 0;
  241 |     let errorCount = 0;
  242 |
  243 |     // APIリクエストを監視
  244 |     page.on('response', response => {
  245 |       if (response.url().includes('/api/')) {
  246 |         apiRequestCount++;
  247 |         if (response.status() >= 200 && response.status() < 300) {
  248 |           successCount++;
  249 |         } else {
  250 |           errorCount++;
  251 |         }
  252 |         console.log(`API Response: ${response.status()} ${response.url()}`);
  253 |       }
  254 |     });
  255 |
  256 |     // 検討モードに切り替えてAPIリクエストを発生させる
  257 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  258 |     if (await studyTab.count() > 0) {
  259 |       await studyTab.click();
  260 |       await page.waitForTimeout(3000); // APIリクエストの完了を待つ
  261 |     }
  262 |
  263 |     console.log(`✅ APIリクエスト合計: ${apiRequestCount}件`);
  264 |     console.log(`✅ 成功: ${successCount}件, エラー: ${errorCount}件`);
  265 |     
  266 |     if (successCount > 0) {
  267 |       console.log('✅ バックエンドとの通信が正常に動作しています');
  268 |     } else if (apiRequestCount === 0) {
  269 |       console.log('⚠️ APIリクエストが発生しませんでした');
  270 |     } else {
  271 |       console.log('❌ バックエンドとの通信でエラーが発生しています');
  272 |     }
  273 |   });
  274 |
  275 |   test('コメント作成後の表示確認テスト', async ({ page }) => {
  276 |     console.log('=== コメント作成後の表示確認テスト ===');
  277 |     
  278 |     // 検討モードに切り替え
  279 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  280 |     if (await studyTab.count() > 0) {
  281 |       await studyTab.click();
  282 |       await page.waitForTimeout(2000);
  283 |       console.log('✅ 検討モードに切り替えました');
  284 |       
  285 |       // コメントボタンが存在するかを確認
  286 |       const commentButtons = page.locator('.comment-toggle-btn').first();
  287 |       if (await commentButtons.count() > 0) {
  288 |         console.log('✅ コメントボタンが見つかりました');
  289 |         
  290 |         // コメントエディターを開く
  291 |         await commentButtons.click();
  292 |         await page.waitForTimeout(1000);
  293 |         
  294 |         // エディターパネルが表示されることを確認
  295 |         const editorPanel = page.locator('.comment-editor-panel');
  296 |         await expect(editorPanel).toBeVisible();
  297 |         console.log('✅ コメントエディターパネルが開きました');
  298 |         
  299 |         // 「+ コメントを追加」ボタンをクリック
  300 |         const addButton = page.locator('.add-comment-btn');
  301 |         if (await addButton.count() > 0) {
  302 |           await addButton.click();
  303 |           await page.waitForTimeout(500);
  304 |           console.log('✅ コメント追加ボタンをクリックしました');
  305 |           
  306 |           // テキストエリアにコメントを入力
  307 |           const textarea = page.locator('.comment-textarea');
  308 |           await textarea.fill('表示確認テストコメント');
  309 |           console.log('✅ コメントを入力しました');
  310 |           
  311 |           // 作成ボタンをクリック
  312 |           const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
  313 |           await createButton.click();
  314 |           console.log('✅ 作成ボタンをクリックしました');
  315 |           
  316 |           // パネルが閉じるまで待機
  317 |           await page.waitForTimeout(2000);
  318 |           
  319 |           // コメントボタンを再度クリックしてパネルを開く
  320 |           await commentButtons.click();
  321 |           await page.waitForTimeout(1000);
  322 |           console.log('✅ コメントパネルを再度開きました');
  323 |           
  324 |           // 作成したコメントが表示されることを確認
  325 |           const commentList = page.locator('.comment-list');
  326 |           const commentItems = page.locator('.comment-item');
  327 |           const commentContent = page.locator('.comment-content');
  328 |           
> 329 |           await expect(commentList).toBeVisible();
      |                                     ^ Error: Timed out 5000ms waiting for expect(locator).toBeVisible()
  330 |           console.log('✅ コメントリストが表示されました');
  331 |           
  332 |           if (await commentItems.count() > 0) {
  333 |             console.log(`✅ コメント項目が${await commentItems.count()}件表示されました`);
  334 |             
  335 |             // 作成したコメントが表示されているかを確認
  336 |             const commentText = await commentContent.first().textContent();
  337 |             if (commentText && commentText.includes('表示確認テストコメント')) {
  338 |               console.log('✅ 作成したコメントが正しく表示されました');
  339 |             } else {
  340 |               console.log(`⚠️ 作成したコメントが見つかりませんでした: ${commentText}`);
  341 |             }
  342 |           } else {
  343 |             console.log('⚠️ コメント項目が表示されませんでした');
  344 |           }
  345 |           
  346 |         } else {
  347 |           console.log('⚠️ コメント追加ボタンが見つかりませんでした');
  348 |         }
  349 |       } else {
  350 |         console.log('⚠️ コメントボタンが見つかりませんでした');
  351 |       }
  352 |     }
  353 |   });
  354 |
  355 |   test('z-index問題の修正確認テスト', async ({ page }) => {
  356 |     console.log('=== z-index問題の修正確認テスト ===');
  357 |     
  358 |     // 検討モードに切り替え
  359 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  360 |     if (await studyTab.count() > 0) {
  361 |       await studyTab.click();
  362 |       await page.waitForTimeout(2000);
  363 |       console.log('✅ 検討モードに切り替えました');
  364 |       
  365 |       // コメントエディターを開く
  366 |       const commentButtons = page.locator('.comment-toggle-btn').first();
  367 |       if (await commentButtons.count() > 0) {
  368 |         await commentButtons.click();
  369 |         await page.waitForTimeout(1000);
  370 |         
  371 |         // エディターパネルが表示されることを確認
  372 |         const editorPanel = page.locator('.comment-editor-panel');
  373 |         await expect(editorPanel).toBeVisible();
  374 |         console.log('✅ コメントエディターパネルが開きました');
  375 |         
  376 |         // パネルのz-indexが適切に設定されているかを確認
  377 |         const panelZIndex = await editorPanel.evaluate(el => 
  378 |           window.getComputedStyle(el).zIndex
  379 |         );
  380 |         
  381 |         if (panelZIndex === '999999' || parseInt(panelZIndex) >= 999999) {
  382 |           console.log(`✅ コメントパネルのz-indexが適切に設定されています: ${panelZIndex}`);
  383 |         } else {
  384 |           console.log(`⚠️ コメントパネルのz-indexが低い可能性があります: ${panelZIndex}`);
  385 |         }
  386 |         
  387 |         // コメントボタンのz-indexがパネルより低いことを確認
  388 |         const commentButton = page.locator('.comment-toggle-btn.panel-open');
  389 |         if (await commentButton.count() > 0) {
  390 |           const buttonZIndex = await commentButton.evaluate(el => 
  391 |             window.getComputedStyle(el).zIndex
  392 |           );
  393 |           console.log(`✅ パネル開放時のコメントボタンz-index: ${buttonZIndex}`);
  394 |           
  395 |           if (parseInt(buttonZIndex) < parseInt(panelZIndex)) {
  396 |             console.log('✅ コメントボタンがパネルの後ろに正しく配置されています');
  397 |           } else {
  398 |             console.log('⚠️ コメントボタンのz-indexが高すぎる可能性があります');
  399 |           }
  400 |         }
  401 |         
  402 |         // 手順項目にホバーしてもパネルが前面に表示されることを確認
  403 |         const moveItems = page.locator('.move-item');
  404 |         if (await moveItems.count() > 0) {
  405 |           // 最初の手順項目にホバー
  406 |           await moveItems.first().hover();
  407 |           await page.waitForTimeout(500);
  408 |           
  409 |           // パネルがまだ表示されていることを確認
  410 |           await expect(editorPanel).toBeVisible();
  411 |           console.log('✅ 手順項目にホバーしてもコメントパネルが前面に表示されています');
  412 |           
  413 |           // 複数の手順項目をテスト（可能であれば）
  414 |           if (await moveItems.count() > 1) {
  415 |             await moveItems.nth(1).hover();
  416 |             await page.waitForTimeout(500);
  417 |             await expect(editorPanel).toBeVisible();
  418 |             console.log('✅ 2つ目の手順項目にホバーしてもコメントパネルが前面に表示されています');
  419 |           }
  420 |           
  421 |           // ホバーを外して通常状態に戻す
  422 |           await moveItems.first().blur();
  423 |           await page.waitForTimeout(500);
  424 |           await expect(editorPanel).toBeVisible();
  425 |           console.log('✅ ホバーを外してもコメントパネルが表示されています');
  426 |         }
  427 |         
  428 |         // パネルを閉じる
  429 |         const closeButton = page.locator('.close-panel-btn');
```