# Test info

- Name: コメント機能UIテスト >> 自動クローズ無効化後のシンプルコメントテスト
- Location: C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:714:3

# Error details

```
Error: Timed out 5000ms waiting for expect(locator).toBeVisible()

Locator: locator('.comment-editor-panel')
Expected: visible
Received: <element(s) not found>
Call log:
  - expect.toBeVisible with timeout 5000ms
  - waiting for locator('.comment-editor-panel')

    at C:\Users\kinoko\shogi_gui\frontend\tests\comment-ui-integration.spec.ts:762:37
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
  662 |           if (isListVisible) {
  663 |             const items = page.locator('.comment-list .comment-item');
  664 |             const itemCount = await items.count();
  665 |             console.log(`📋 表示されているコメント数: ${itemCount}件`);
  666 |             
  667 |             for (let i = 0; i < itemCount; i++) {
  668 |               const content = await items.nth(i).locator('.comment-content').textContent();
  669 |               console.log(`📋 コメント${i + 1}: ${content}`);
  670 |             }
  671 |             
  672 |             // 作成したコメントがあるかを確認
  673 |             const createdComment = page.locator('.comment-content').filter({ hasText: testComment });
  674 |             if (await createdComment.count() > 0) {
  675 |               console.log('✅ 作成したコメントが正しく表示されています');
  676 |             } else {
  677 |               console.log('❌ 作成したコメントが表示されていません');
  678 |             }
  679 |           } else {
  680 |             console.log('❌ コメントリストが表示されていません');
  681 |             
  682 |             // デバッグ情報として他の要素の存在も確認
  683 |             const createSection = page.locator('.comment-create');
  684 |             const newSection = page.locator('.comment-new');
  685 |             const loadingSection = page.locator('.loading');
  686 |             
  687 |             console.log(`📋 add-comment-btnの表示状態: ${await createSection.isVisible()}`);
  688 |             console.log(`📋 comment-newの表示状態: ${await newSection.isVisible()}`);
  689 |             console.log(`📋 loadingの表示状態: ${await loadingSection.isVisible()}`);
  690 |           }
  691 |           
  692 |           // 6. ブラウザコンソールのエラーをチェック
  693 |           const logs: string[] = [];
  694 |           page.on('console', msg => {
  695 |             if (msg.type() === 'error') {
  696 |               logs.push(msg.text());
  697 |             }
  698 |           });
  699 |           
  700 |           if (logs.length > 0) {
  701 |             console.log('❌ ブラウザコンソールエラー:');
  702 |             logs.forEach(log => console.log(`  - ${log}`));
  703 |           }
  704 |           
  705 |         } else {
  706 |           console.log('⚠️ コメント追加ボタンが見つかりませんでした');
  707 |         }
  708 |       } else {
  709 |         console.log('⚠️ コメントボタンが見つかりませんでした');
  710 |       }
  711 |     }
  712 |   });
  713 |
  714 |   test('自動クローズ無効化後のシンプルコメントテスト', async ({ page }) => {
  715 |     console.log('=== 自動クローズ無効化後のシンプルコメントテスト ===');
  716 |     
  717 |     // 検討モードに切り替え
  718 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  719 |     if (await studyTab.count() > 0) {
  720 |       await studyTab.click();
  721 |       await page.waitForTimeout(2000);
  722 |       console.log('✅ 検討モードに切り替えました');
  723 |       
  724 |       // コメントボタンを開く
  725 |       const commentButtons = page.locator('.comment-toggle-btn').first();
  726 |       if (await commentButtons.count() > 0) {
  727 |         console.log('✅ コメントボタンが見つかりました');
  728 |         
  729 |         // コメントエディターを開く
  730 |         await commentButtons.click();
  731 |         await page.waitForTimeout(1000);
  732 |         
  733 |         const editorPanel = page.locator('.comment-editor-panel');
  734 |         await expect(editorPanel).toBeVisible();
  735 |         console.log('✅ コメントエディターパネルが開きました');
  736 |         
  737 |         // 「テスト」コメントを1つだけ作成
  738 |         const addButton = page.locator('.add-comment-btn');
  739 |         if (await addButton.count() > 0) {
  740 |           await addButton.click();
  741 |           await page.waitForTimeout(500);
  742 |           
  743 |           const textarea = page.locator('.comment-textarea');
  744 |           const testComment = 'テスト';
  745 |           await textarea.fill(testComment);
  746 |           console.log(`✅ コメントを入力しました: "${testComment}"`);
  747 |           
  748 |           // 作成ボタンをクリック
  749 |           const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
  750 |           await createButton.click();
  751 |           console.log('✅ 作成ボタンをクリックしました');
  752 |           
  753 |           // 成功メッセージが表示されることを確認
  754 |           const successMessage = page.locator('.success-message');
  755 |           await expect(successMessage).toBeVisible();
  756 |           console.log('✅ 成功メッセージが表示されました');
  757 |           
  758 |           // しっかりと待機（API呼び出し完了まで）
  759 |           await page.waitForTimeout(5000);
  760 |           
  761 |           // パネルがまだ開いていることを確認
> 762 |           await expect(editorPanel).toBeVisible();
      |                                     ^ Error: Timed out 5000ms waiting for expect(locator).toBeVisible()
  763 |           console.log('✅ パネルが開いたままです');
  764 |           
  765 |           // コメントリストが表示されることを確認
  766 |           const commentList = page.locator('.comment-list');
  767 |           if (await commentList.isVisible()) {
  768 |             console.log('✅ コメントリストが表示されました');
  769 |             
  770 |             // 作成したコメントが表示されることを確認
  771 |             const commentItems = page.locator('.comment-list .comment-item');
  772 |             const itemCount = await commentItems.count();
  773 |             console.log(`📋 コメント項目数: ${itemCount}件`);
  774 |             
  775 |             if (itemCount > 0) {
  776 |               // 最初のコメントの内容を確認
  777 |               const firstComment = commentItems.first();
  778 |               const contentElement = firstComment.locator('.comment-content');
  779 |               
  780 |               // 表示状態を確認
  781 |               const isVisible = await contentElement.isVisible();
  782 |               console.log(`📋 コメント内容の表示状態: ${isVisible}`);
  783 |               
  784 |               if (isVisible) {
  785 |                 // テキスト内容を確認
  786 |                 const contentText = await contentElement.textContent();
  787 |                 console.log(`📋 コメント内容: "${contentText}"`);
  788 |                 
  789 |                 // CSS確認
  790 |                 const styles = await contentElement.evaluate(el => {
  791 |                   const computed = window.getComputedStyle(el);
  792 |                   return {
  793 |                     color: computed.color,
  794 |                     backgroundColor: computed.backgroundColor,
  795 |                     fontSize: computed.fontSize,
  796 |                     fontWeight: computed.fontWeight,
  797 |                     display: computed.display,
  798 |                     visibility: computed.visibility,
  799 |                     opacity: computed.opacity
  800 |                   };
  801 |                 });
  802 |                 
  803 |                 console.log('📋 CSS スタイル:');
  804 |                 console.log(`  - color: ${styles.color}`);
  805 |                 console.log(`  - backgroundColor: ${styles.backgroundColor}`);
  806 |                 console.log(`  - fontSize: ${styles.fontSize}`);
  807 |                 console.log(`  - fontWeight: ${styles.fontWeight}`);
  808 |                 console.log(`  - display: ${styles.display}`);
  809 |                 console.log(`  - visibility: ${styles.visibility}`);
  810 |                 console.log(`  - opacity: ${styles.opacity}`);
  811 |                 
  812 |                 if (contentText && contentText.includes('テスト')) {
  813 |                   console.log('✅ 「テスト」コメントが正しく表示されています！');
  814 |                 } else {
  815 |                   console.log(`❌ コメント内容が期待と違います: "${contentText}"`);
  816 |                 }
  817 |               } else {
  818 |                 console.log('❌ コメント内容要素が見えません');
  819 |               }
  820 |             } else {
  821 |               console.log('❌ コメント項目が見つかりません');
  822 |             }
  823 |           } else {
  824 |             console.log('❌ コメントリストが表示されていません');
  825 |             
  826 |             // 代替要素の確認
  827 |             const addCommentBtn = page.locator('.add-comment-btn');
  828 |             const commentNew = page.locator('.comment-new');
  829 |             const loading = page.locator('.loading');
  830 |             
  831 |             console.log(`📋 add-comment-btn表示: ${await addCommentBtn.isVisible()}`);
  832 |             console.log(`📋 comment-new表示: ${await commentNew.isVisible()}`);
  833 |             console.log(`📋 loading表示: ${await loading.isVisible()}`);
  834 |           }
  835 |           
  836 |         } else {
  837 |           console.log('⚠️ コメント追加ボタンが見つかりませんでした');
  838 |         }
  839 |       } else {
  840 |         console.log('⚠️ コメントボタンが見つかりませんでした');
  841 |       }
  842 |     }
  843 |   });
  844 |
  845 |   test('修正後のコメント表示とタイミング確認テスト', async ({ page }) => {
  846 |     console.log('=== 修正後のコメント表示とタイミング確認テスト ===');
  847 |     
  848 |     // 検討モードに切り替え
  849 |     const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
  850 |     if (await studyTab.count() > 0) {
  851 |       await studyTab.click();
  852 |       await page.waitForTimeout(2000);
  853 |       console.log('✅ 検討モードに切り替えました');
  854 |       
  855 |       // コメントボタンを開く
  856 |       const commentButtons = page.locator('.comment-toggle-btn').first();
  857 |       if (await commentButtons.count() > 0) {
  858 |         console.log('✅ コメントボタンが見つかりました');
  859 |         
  860 |         // コメントエディターを開く
  861 |         await commentButtons.click();
  862 |         await page.waitForTimeout(1000);
```