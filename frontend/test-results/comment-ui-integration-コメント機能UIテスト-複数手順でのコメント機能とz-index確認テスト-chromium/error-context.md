# Test info

- Name: コメント機能UIテスト >> 複数手順でのコメント機能とz-index確認テスト
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:439:3

# Error details

```
Error: Timed out 5000ms waiting for expect(locator).toBeVisible()

Locator: locator('.comment-editor-panel').first()
Expected: visible
Received: <element(s) not found>
Call log:
  - expect.toBeVisible with timeout 5000ms
  - waiting for locator('.comment-editor-panel').first()

    at C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:495:39
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
  430 |         if (await closeButton.count() > 0) {
  431 |           await closeButton.click();
  432 |           await page.waitForTimeout(500);
  433 |           console.log('✅ コメントパネルを閉じました');
  434 |         }
  435 |       }
  436 |     }
  437 |   });
  438 |
  439 |   test('複数手順でのコメント機能とz-index確認テスト', async ({ page }) => {
  440 |     console.log('=== 複数手順でのコメント機能とz-index確認テスト ===');
  441 |     
  442 |     // 検討モードに切り替え
  443 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  444 |     if (await studyTab.count() > 0) {
  445 |       await studyTab.click();
  446 |       await page.waitForTimeout(2000);
  447 |       console.log('✅ 検討モードに切り替えました');
  448 |       
  449 |       // 手順リストを確認
  450 |       const moveItems = page.locator('.move-item');
  451 |       const moveCount = await moveItems.count();
  452 |       console.log(`✅ 現在の手順数: ${moveCount}件`);
  453 |       
  454 |       // 1手目にコメントを追加
  455 |       if (moveCount >= 1) {
  456 |         const firstMoveItem = moveItems.first();
  457 |         const firstCommentButton = firstMoveItem.locator('.comment-toggle-btn');
  458 |         
  459 |         if (await firstCommentButton.count() > 0) {
  460 |           console.log('✅ 1手目のコメントボタンが見つかりました');
  461 |           
  462 |           await firstCommentButton.click();
  463 |           await page.waitForTimeout(1000);
  464 |           
  465 |           // 1手目のコメントパネルが開いたことを確認
  466 |           const commentPanel = page.locator('.comment-editor-panel').first();
  467 |           await expect(commentPanel).toBeVisible();
  468 |           console.log('✅ 1手目のコメントパネルが開きました');
  469 |           
  470 |           // 1手目にコメントを追加
  471 |           const addButton = commentPanel.locator('.add-comment-btn');
  472 |           if (await addButton.count() > 0) {
  473 |             await addButton.click();
  474 |             await page.waitForTimeout(500);
  475 |             
  476 |             const textarea = commentPanel.locator('.comment-textarea');
  477 |             await textarea.fill('1手目のテストコメントです');
  478 |             console.log('✅ 1手目にコメントを入力しました');
  479 |             
  480 |             const createButton = commentPanel.locator('.save-btn').filter({ hasText: '作成' });
  481 |             await createButton.click();
  482 |             console.log('✅ 1手目のコメントを作成しました');
  483 |             
  484 |             // パネルが閉じるまで待機
  485 |             await page.waitForTimeout(2000);
  486 |           }
  487 |           
  488 |           // 1手目のコメントパネルを再度開いてz-index問題をテスト
  489 |           console.log('🔍 z-index競合問題をテストします...');
  490 |           
  491 |           await firstCommentButton.click();
  492 |           await page.waitForTimeout(1000);
  493 |           
  494 |           const reopenedPanel = page.locator('.comment-editor-panel').first();
> 495 |           await expect(reopenedPanel).toBeVisible();
      |                                       ^ Error: Timed out 5000ms waiting for expect(locator).toBeVisible()
  496 |           console.log('✅ 1手目のコメントパネルを再度開きました');
  497 |           
  498 |           // パネルのz-indexを確認
  499 |           const panelZIndex = await reopenedPanel.evaluate(el => 
  500 |             window.getComputedStyle(el).zIndex
  501 |           );
  502 |           console.log(`📋 コメントパネルのz-index: ${panelZIndex}`);
  503 |           
  504 |           // コメントボタンのz-indexを確認（panel-openクラス付き）
  505 |           const buttonZIndex = await firstCommentButton.evaluate(el => 
  506 |             window.getComputedStyle(el).zIndex
  507 |           );
  508 |           console.log(`📋 コメントボタンのz-index: ${buttonZIndex}`);
  509 |           
  510 |           // コメントボタンがpanel-openクラスを持っているかを確認
  511 |           const hasOpenClass = await firstCommentButton.evaluate(el => 
  512 |             el.classList.contains('panel-open')
  513 |           );
  514 |           console.log(`📋 コメントボタンにpanel-openクラス: ${hasOpenClass}`);
  515 |           
  516 |           // z-index値の数値比較
  517 |           const panelZ = parseInt(panelZIndex) || 0;
  518 |           const buttonZ = parseInt(buttonZIndex) || 0;
  519 |           
  520 |           if (panelZ > buttonZ) {
  521 |             console.log('✅ パネルのz-indexがボタンより高く設定されています');
  522 |           } else {
  523 |             console.log('⚠️ z-index設定に問題がある可能性があります');
  524 |           }
  525 |           
  526 |           // 同じ手順項目の他の部分にホバーしてテスト
  527 |           const moveContent = firstMoveItem.locator('.move-content');
  528 |           if (await moveContent.count() > 0) {
  529 |             await moveContent.hover();
  530 |             await page.waitForTimeout(500);
  531 |             
  532 |             await expect(reopenedPanel).toBeVisible();
  533 |             console.log('✅ 同じ手順項目にホバーしてもパネルが前面に表示されています');
  534 |           }
  535 |           
  536 |           // 他の手順項目があればホバーしてテスト
  537 |           if (moveCount > 1) {
  538 |             for (let i = 1; i < Math.min(moveCount, 3); i++) {
  539 |               const otherMoveItem = moveItems.nth(i);
  540 |               await otherMoveItem.hover();
  541 |               await page.waitForTimeout(300);
  542 |               
  543 |               await expect(reopenedPanel).toBeVisible();
  544 |               console.log(`✅ ${i + 1}手目にホバーしてもパネルが前面に表示されています`);
  545 |               
  546 |               // その手順項目のコメントボタンにもホバー
  547 |               const otherCommentButton = otherMoveItem.locator('.comment-toggle-btn');
  548 |               if (await otherCommentButton.count() > 0) {
  549 |                 await otherCommentButton.hover();
  550 |                 await page.waitForTimeout(300);
  551 |                 
  552 |                 await expect(reopenedPanel).toBeVisible();
  553 |                 console.log(`✅ ${i + 1}手目のコメントボタンにホバーしてもパネルが前面に表示されています`);
  554 |               }
  555 |             }
  556 |           }
  557 |           
  558 |           // 最終的にパネルを閉じる
  559 |           const closeButton = reopenedPanel.locator('.close-panel-btn');
  560 |           if (await closeButton.count() > 0) {
  561 |             await closeButton.click();
  562 |             await page.waitForTimeout(500);
  563 |             console.log('✅ コメントパネルを閉じました');
  564 |           }
  565 |           
  566 |         } else {
  567 |           console.log('⚠️ 1手目のコメントボタンが見つかりませんでした');
  568 |         }
  569 |       } else {
  570 |         console.log('⚠️ 手順が見つかりません');
  571 |       }
  572 |     }
  573 |   });
  574 |
  575 |   test('コメント表示問題のデバッグテスト', async ({ page }) => {
  576 |     console.log('=== コメント表示問題のデバッグテスト ===');
  577 |     
  578 |     // APIレスポンスを監視
  579 |     const apiResponses: any[] = [];
  580 |     page.on('response', response => {
  581 |       if (response.url().includes('/api/') && response.url().includes('comment')) {
  582 |         apiResponses.push({
  583 |           url: response.url(),
  584 |           status: response.status(),
  585 |           method: response.request().method()
  586 |         });
  587 |       }
  588 |     });
  589 |
  590 |     // 検討モードに切り替え
  591 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  592 |     if (await studyTab.count() > 0) {
  593 |       await studyTab.click();
  594 |       await page.waitForTimeout(2000);
  595 |       console.log('✅ 検討モードに切り替えました');
```