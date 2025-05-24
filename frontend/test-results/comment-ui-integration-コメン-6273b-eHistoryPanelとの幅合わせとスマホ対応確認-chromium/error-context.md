# Test info

- Name: コメント機能UIテスト >> MoveHistoryPanelとの幅合わせとスマホ対応確認
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:1454:3

# Error details

```
Error: locator.evaluate: Test timeout of 30000ms exceeded.
Call log:
  - waiting for locator('.comment-editor-panel')

    at C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:1521:51
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
- button:
  - img
```

# Test source

```ts
  1421 |             if (await saveButton.count() > 0) {
  1422 |               const saveButtonStyles = await saveButton.evaluate(el => {
  1423 |                 const computed = window.getComputedStyle(el);
  1424 |                 return {
  1425 |                   background: computed.background,
  1426 |                   borderRadius: computed.borderRadius,
  1427 |                   minHeight: computed.minHeight,
  1428 |                   fontWeight: computed.fontWeight
  1429 |                 };
  1430 |               });
  1431 |               
  1432 |               console.log('📋 保存ボタンスタイル:');
  1433 |               console.log(`  - background: ${saveButtonStyles.background.substring(0, 50)}...`);
  1434 |               console.log(`  - borderRadius: ${saveButtonStyles.borderRadius}`);
  1435 |               console.log(`  - minHeight: ${saveButtonStyles.minHeight}`);
  1436 |               console.log(`  - fontWeight: ${saveButtonStyles.fontWeight}`);
  1437 |               
  1438 |               // ホバー効果確認
  1439 |               await saveButton.hover();
  1440 |               await page.waitForTimeout(500);
  1441 |               console.log('✅ 保存ボタンのホバー効果を確認');
  1442 |             }
  1443 |           }
  1444 |         }
  1445 |         
  1446 |         // パネルを閉じる
  1447 |         await page.keyboard.press('Escape');
  1448 |         await page.waitForTimeout(500);
  1449 |         console.log('✅ UI改善テスト完了');
  1450 |       }
  1451 |     }
  1452 |   });
  1453 |
  1454 |   test('MoveHistoryPanelとの幅合わせとスマホ対応確認', async ({ page }) => {
  1455 |     console.log('=== MoveHistoryPanelとの幅合わせとスマホ対応確認 ===');
  1456 |     
  1457 |     // デスクトップサイズでテスト
  1458 |     await page.setViewportSize({ width: 1200, height: 800 });
  1459 |     console.log('📱 デスクトップサイズ (1200x800) に設定');
  1460 |     
  1461 |     // 検討モードに切り替え
  1462 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  1463 |     if (await studyTab.count() > 0) {
  1464 |       await studyTab.click();
  1465 |       await page.waitForTimeout(2000);
  1466 |       console.log('✅ 検討モードに切り替えました');
  1467 |       
  1468 |       // MoveHistoryPanelの幅を確認
  1469 |       const moveHistoryPanel = page.locator('.move-history-panel');
  1470 |       if (await moveHistoryPanel.count() > 0) {
  1471 |         const panelBox = await moveHistoryPanel.boundingBox();
  1472 |         const panelWidth = panelBox?.width || 0;
  1473 |         console.log(`📋 MoveHistoryPanelの幅: ${panelWidth}px`);
  1474 |         
  1475 |         // コメントボタンを開く
  1476 |         const commentButtons = page.locator('.comment-toggle-btn').first();
  1477 |         if (await commentButtons.count() > 0) {
  1478 |           await commentButtons.click();
  1479 |           await page.waitForTimeout(1000);
  1480 |           
  1481 |           const commentPanel = page.locator('.comment-editor-panel');
  1482 |           await expect(commentPanel).toBeVisible();
  1483 |           console.log('✅ コメントパネルが開きました');
  1484 |           
  1485 |           // デスクトップでのコメントパネル幅確認
  1486 |           const commentPanelBox = await commentPanel.boundingBox();
  1487 |           const commentPanelWidth = commentPanelBox?.width || 0;
  1488 |           console.log(`📋 コメントパネルの幅: ${commentPanelWidth}px`);
  1489 |           
  1490 |           // 幅が一致するかチェック（280px）
  1491 |           if (Math.abs(commentPanelWidth - 280) <= 2) {
  1492 |             console.log('✅ コメントパネルの幅がMoveHistoryPanelと一致しています');
  1493 |           } else {
  1494 |             console.log(`⚠️ 幅が一致しません。期待値: 280px, 実際: ${commentPanelWidth}px`);
  1495 |           }
  1496 |           
  1497 |           // パネルのposition確認
  1498 |           const panelStyles = await commentPanel.evaluate(el => {
  1499 |             const computed = window.getComputedStyle(el);
  1500 |             return {
  1501 |               position: computed.position,
  1502 |               width: computed.width,
  1503 |               maxWidth: computed.maxWidth
  1504 |             };
  1505 |           });
  1506 |           
  1507 |           console.log('📋 デスクトップでのパネルスタイル:');
  1508 |           console.log(`  - position: ${panelStyles.position}`);
  1509 |           console.log(`  - width: ${panelStyles.width}`);
  1510 |           console.log(`  - maxWidth: ${panelStyles.maxWidth}`);
  1511 |           
  1512 |           await page.keyboard.press('Escape');
  1513 |           await page.waitForTimeout(500);
  1514 |         }
  1515 |       }
  1516 |       
  1517 |              // タブレット（768px）でのテスト       await page.setViewportSize({ width: 768, height: 1024 });       console.log('📱 タブレットサイズ (768x1024) に設定');       await page.waitForTimeout(1000);              const tabletCommentButtons = page.locator('.comment-toggle-btn').first();       await tabletCommentButtons.click();
  1518 |       await page.waitForTimeout(1000);
  1519 |       
  1520 |       const tabletPanel = page.locator('.comment-editor-panel');
> 1521 |       const tabletPanelStyles = await tabletPanel.evaluate(el => {
       |                                                   ^ Error: locator.evaluate: Test timeout of 30000ms exceeded.
  1522 |         const computed = window.getComputedStyle(el);
  1523 |         return {
  1524 |           position: computed.position,
  1525 |           width: computed.width,
  1526 |           maxWidth: computed.maxWidth,
  1527 |           transform: computed.transform,
  1528 |           left: computed.left
  1529 |         };
  1530 |       });
  1531 |       
  1532 |       console.log('📋 タブレットでのパネルスタイル:');
  1533 |       console.log(`  - position: ${tabletPanelStyles.position}`);
  1534 |       console.log(`  - width: ${tabletPanelStyles.width}`);
  1535 |       console.log(`  - maxWidth: ${tabletPanelStyles.maxWidth}`);
  1536 |       console.log(`  - transform: ${tabletPanelStyles.transform}`);
  1537 |       console.log(`  - left: ${tabletPanelStyles.left}`);
  1538 |       
  1539 |       if (tabletPanelStyles.position === 'fixed') {
  1540 |         console.log('✅ タブレットサイズでfixed positionに切り替わりました');
  1541 |       }
  1542 |       
  1543 |       await page.keyboard.press('Escape');
  1544 |       await page.waitForTimeout(500);
  1545 |       
  1546 |              // モバイル（480px以下）でのテスト       await page.setViewportSize({ width: 375, height: 667 });       console.log('📱 モバイルサイズ (375x667) に設定');       await page.waitForTimeout(1000);              const mobileCommentButtons = page.locator('.comment-toggle-btn').first();       await mobileCommentButtons.click();
  1547 |       await page.waitForTimeout(1000);
  1548 |       
  1549 |       const mobilePanel = page.locator('.comment-editor-panel');
  1550 |       const mobilePanelStyles = await mobilePanel.evaluate(el => {
  1551 |         const computed = window.getComputedStyle(el);
  1552 |         return {
  1553 |           position: computed.position,
  1554 |           top: computed.top,
  1555 |           left: computed.left,
  1556 |           right: computed.right,
  1557 |           width: computed.width,
  1558 |           maxHeight: computed.maxHeight,
  1559 |           borderRadius: computed.borderRadius
  1560 |         };
  1561 |       });
  1562 |       
  1563 |       console.log('📋 モバイルでのパネルスタイル:');
  1564 |       console.log(`  - position: ${mobilePanelStyles.position}`);
  1565 |       console.log(`  - top: ${mobilePanelStyles.top}`);
  1566 |       console.log(`  - left: ${mobilePanelStyles.left}`);
  1567 |       console.log(`  - right: ${mobilePanelStyles.right}`);
  1568 |       console.log(`  - width: ${mobilePanelStyles.width}`);
  1569 |       console.log(`  - maxHeight: ${mobilePanelStyles.maxHeight}`);
  1570 |       console.log(`  - borderRadius: ${mobilePanelStyles.borderRadius}`);
  1571 |       
  1572 |       // オーバーレイ背景の確認
  1573 |       const overlay = page.locator('.comment-editor:has(.comment-editor-panel)');
  1574 |       if (await overlay.count() > 0) {
  1575 |         const overlayStyles = await overlay.evaluate(el => {
  1576 |           const before = window.getComputedStyle(el, '::before');
  1577 |           return {
  1578 |             content: before.content,
  1579 |             background: before.background,
  1580 |             position: before.position
  1581 |           };
  1582 |         });
  1583 |         
  1584 |         console.log('📋 オーバーレイ背景:');
  1585 |         console.log(`  - content: ${overlayStyles.content}`);
  1586 |         console.log(`  - background: ${overlayStyles.background.substring(0, 50)}...`);
  1587 |         console.log(`  - position: ${overlayStyles.position}`);
  1588 |         
  1589 |         if (overlayStyles.content !== 'none' && overlayStyles.content !== '""') {
  1590 |           console.log('✅ モバイルでオーバーレイ背景が表示されています');
  1591 |         }
  1592 |       }
  1593 |       
  1594 |       // タッチフレンドリーなサイズの確認
  1595 |       const mobileButton = page.locator('.comment-toggle-btn');
  1596 |       const buttonBox = await mobileButton.boundingBox();
  1597 |       if (buttonBox && buttonBox.height >= 40) {
  1598 |         console.log('✅ モバイルでタッチフレンドリーなボタンサイズです');
  1599 |       } else {
  1600 |         console.log(`⚠️ ボタンサイズが小さい可能性があります: ${buttonBox?.height}px`);
  1601 |       }
  1602 |       
  1603 |       await page.keyboard.press('Escape');
  1604 |       await page.waitForTimeout(500);
  1605 |       
  1606 |       // 元のサイズに戻す
  1607 |       await page.setViewportSize({ width: 1200, height: 800 });
  1608 |       console.log('✅ パネル幅調整とスマホ対応テスト完了');
  1609 |     }
  1610 |   });
  1611 |
  1612 |   test('狭いパネル幅でのコンテンツ表示確認', async ({ page }) => {
  1613 |     console.log('=== 狭いパネル幅でのコンテンツ表示確認 ===');
  1614 |     
  1615 |     // デスクトップサイズで開始
  1616 |     await page.setViewportSize({ width: 1200, height: 800 });
  1617 |     
  1618 |     // 検討モードに切り替え
  1619 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  1620 |     if (await studyTab.count() > 0) {
  1621 |       await studyTab.click();
```