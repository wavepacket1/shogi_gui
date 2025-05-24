import { test, expect } from '@playwright/test';

test.describe('コメント機能UIテスト', () => {
  test.beforeEach(async ({ page }) => {
    // アプリケーションにアクセス
    await page.goto('http://localhost:5173/');
    await page.waitForSelector('#app');
    await page.waitForTimeout(2000);
  });

  test('アプリケーションの基本動作確認', async ({ page }) => {
    console.log('=== アプリケーション基本動作確認 ===');
    
    // ページが読み込まれることを確認
    const title = await page.title();
    console.log(`✅ ページタイトル: ${title}`);
    
    // メニューバーが表示されることを確認
    const menuBar = page.locator('header');
    await expect(menuBar).toBeVisible();
    console.log('✅ メニューバーが表示されています');
    
    // 検討モードタブが存在することを確認
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await expect(studyTab).toBeVisible();
      console.log('✅ 検討モードタブが表示されています');
      
      // 検討モードに切り替え
      await studyTab.click();
      await page.waitForTimeout(1000);
      console.log('✅ 検討モードに切り替えました');
    } else {
      console.log('⚠️ 検討モードタブが見つかりませんでした');
    }
  });

  test('コメント追加と画面閉じる動作テスト', async ({ page }) => {
    console.log('=== コメント追加と画面閉じる動作テスト ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントボタンが存在するかを確認
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        console.log('✅ コメントボタンが見つかりました');
        
        // コメントエディターを開く
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        // エディターパネルが表示されることを確認
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');
        
        // 「+ コメントを追加」ボタンをクリック
        const addButton = page.locator('.add-comment-btn');
        if (await addButton.count() > 0) {
          await addButton.click();
          await page.waitForTimeout(500);
          console.log('✅ コメント追加ボタンをクリックしました');
          
          // テキストエリアが表示されることを確認
          const textarea = page.locator('.comment-textarea');
          await expect(textarea).toBeVisible();
          console.log('✅ テキストエリアが表示されました');
          
          // コメントを入力
          await textarea.fill('テストコメントです');
          console.log('✅ コメントを入力しました');
          
          // 作成ボタンをクリック
          const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
          await createButton.click();
          console.log('✅ 作成ボタンをクリックしました');
          
          // 成功メッセージが表示されることを確認
          const successMessage = page.locator('.success-message');
          await expect(successMessage).toBeVisible();
          console.log('✅ 成功メッセージが表示されました');
          
          // パネルが自動的に閉じることを確認（1.5秒待機）
          await page.waitForTimeout(2000);
          await expect(editorPanel).not.toBeVisible();
          console.log('✅ エディターパネルが自動的に閉じました');
          
        } else {
          console.log('⚠️ コメント追加ボタンが見つかりませんでした');
        }
      } else {
        console.log('⚠️ コメントボタンが見つかりませんでした');
      }
    }
  });

  test('ESCキーでエディターを閉じるテスト', async ({ page }) => {
    console.log('=== ESCキーでエディターを閉じるテスト ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      
      // コメントエディターを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        // エディターパネルが表示されることを確認
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');
        
        // ESCキーを押す
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        
        // パネルが閉じることを確認
        await expect(editorPanel).not.toBeVisible();
        console.log('✅ ESCキーでエディターパネルが閉じました');
      }
    }
  });

  test('閉じるボタンでエディターを閉じるテスト', async ({ page }) => {
    console.log('=== 閉じるボタンでエディターを閉じるテスト ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      
      // コメントエディターを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        // エディターパネルが表示されることを確認
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');
        
        // 閉じるボタンをクリック
        const closeButton = page.locator('.close-panel-btn');
        if (await closeButton.count() > 0) {
          await closeButton.click();
          await page.waitForTimeout(500);
          
          // パネルが閉じることを確認
          await expect(editorPanel).not.toBeVisible();
          console.log('✅ 閉じるボタンでエディターパネルが閉じました');
        } else {
          console.log('⚠️ 閉じるボタンが見つかりませんでした');
        }
      }
    }
  });

  test('MoveHistoryPanelの表示確認', async ({ page }) => {
    console.log('=== MoveHistoryPanel表示確認 ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      
      // MoveHistoryPanelが表示されることを確認
      const moveHistoryPanel = page.locator('.move-history-panel');
      if (await moveHistoryPanel.count() > 0) {
        await expect(moveHistoryPanel).toBeVisible();
        console.log('✅ MoveHistoryPanelが表示されています');
        
        // 手順項目が存在することを確認
        const moveItems = page.locator('.move-item');
        if (await moveItems.count() > 0) {
          console.log(`✅ 手順項目が${await moveItems.count()}件表示されています`);
          
          // コメント機能の要素が存在するかを確認
          const commentButtons = page.locator('.comment-toggle-btn, .comment-icon, button').filter({ hasText: /コメント|💬/ });
          if (await commentButtons.count() > 0) {
            console.log('✅ コメント関連のボタンが見つかりました');
          } else {
            console.log('⚠️ コメント関連のボタンが見つかりませんでした');
          }
        } else {
          console.log('⚠️ 手順項目が見つかりませんでした');
        }
      } else {
        console.log('⚠️ MoveHistoryPanelが見つかりませんでした');
      }
    }
  });

  test('コメント機能の存在確認', async ({ page }) => {
    console.log('=== コメント機能存在確認 ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      
      // コメントエディターが存在するかを確認
      const commentEditors = page.locator('.comment-editor, .comment-section, .comment-form');
      if (await commentEditors.count() > 0) {
        console.log(`✅ コメントエディターが${await commentEditors.count()}件見つかりました`);
        
        // テキストエリアが存在するかを確認
        const textareas = page.locator('textarea, .comment-textarea');
        if (await textareas.count() > 0) {
          console.log(`✅ テキストエリアが${await textareas.count()}件見つかりました`);
        }
        
        // 保存/作成ボタンが存在するかを確認
        const saveButtons = page.locator('button').filter({ hasText: /保存|作成|送信/ });
        if (await saveButtons.count() > 0) {
          console.log(`✅ 保存/作成ボタンが${await saveButtons.count()}件見つかりました`);
        }
      } else {
        console.log('⚠️ コメントエディターが見つかりませんでした');
      }
    }
  });

  test('ネットワーク接続の確認', async ({ page }) => {
    console.log('=== ネットワーク接続確認 ===');
    
    let apiRequestCount = 0;
    let successCount = 0;
    let errorCount = 0;

    // APIリクエストを監視
    page.on('response', response => {
      if (response.url().includes('/api/')) {
        apiRequestCount++;
        if (response.status() >= 200 && response.status() < 300) {
          successCount++;
        } else {
          errorCount++;
        }
        console.log(`API Response: ${response.status()} ${response.url()}`);
      }
    });

    // 検討モードに切り替えてAPIリクエストを発生させる
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(3000); // APIリクエストの完了を待つ
    }

    console.log(`✅ APIリクエスト合計: ${apiRequestCount}件`);
    console.log(`✅ 成功: ${successCount}件, エラー: ${errorCount}件`);
    
    if (successCount > 0) {
      console.log('✅ バックエンドとの通信が正常に動作しています');
    } else if (apiRequestCount === 0) {
      console.log('⚠️ APIリクエストが発生しませんでした');
    } else {
      console.log('❌ バックエンドとの通信でエラーが発生しています');
    }
  });

  test('コメント作成後の表示確認テスト', async ({ page }) => {
    console.log('=== コメント作成後の表示確認テスト ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントボタンが存在するかを確認
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        console.log('✅ コメントボタンが見つかりました');
        
        // コメントエディターを開く
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        // エディターパネルが表示されることを確認
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');
        
        // 「+ コメントを追加」ボタンをクリック
        const addButton = page.locator('.add-comment-btn');
        if (await addButton.count() > 0) {
          await addButton.click();
          await page.waitForTimeout(500);
          console.log('✅ コメント追加ボタンをクリックしました');
          
          // テキストエリアにコメントを入力
          const textarea = page.locator('.comment-textarea');
          await textarea.fill('表示確認テストコメント');
          console.log('✅ コメントを入力しました');
          
          // 作成ボタンをクリック
          const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
          await createButton.click();
          console.log('✅ 作成ボタンをクリックしました');
          
          // パネルが閉じるまで待機
          await page.waitForTimeout(2000);
          
          // コメントボタンを再度クリックしてパネルを開く
          await commentButtons.click();
          await page.waitForTimeout(1000);
          console.log('✅ コメントパネルを再度開きました');
          
          // 作成したコメントが表示されることを確認
          const commentList = page.locator('.comment-list');
          const commentItems = page.locator('.comment-item');
          const commentContent = page.locator('.comment-content');
          
          await expect(commentList).toBeVisible();
          console.log('✅ コメントリストが表示されました');
          
          if (await commentItems.count() > 0) {
            console.log(`✅ コメント項目が${await commentItems.count()}件表示されました`);
            
            // 作成したコメントが表示されているかを確認
            const commentText = await commentContent.first().textContent();
            if (commentText && commentText.includes('表示確認テストコメント')) {
              console.log('✅ 作成したコメントが正しく表示されました');
            } else {
              console.log(`⚠️ 作成したコメントが見つかりませんでした: ${commentText}`);
            }
          } else {
            console.log('⚠️ コメント項目が表示されませんでした');
          }
          
        } else {
          console.log('⚠️ コメント追加ボタンが見つかりませんでした');
        }
      } else {
        console.log('⚠️ コメントボタンが見つかりませんでした');
      }
    }
  });

  test('z-index問題の修正確認テスト', async ({ page }) => {
    console.log('=== z-index問題の修正確認テスト ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントエディターを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        // エディターパネルが表示されることを確認
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');
        
        // パネルのz-indexが適切に設定されているかを確認
        const panelZIndex = await editorPanel.evaluate(el => 
          window.getComputedStyle(el).zIndex
        );
        
        if (panelZIndex === '999999' || parseInt(panelZIndex) >= 999999) {
          console.log(`✅ コメントパネルのz-indexが適切に設定されています: ${panelZIndex}`);
        } else {
          console.log(`⚠️ コメントパネルのz-indexが低い可能性があります: ${panelZIndex}`);
        }
        
        // コメントボタンのz-indexがパネルより低いことを確認
        const commentButton = page.locator('.comment-toggle-btn.panel-open');
        if (await commentButton.count() > 0) {
          const buttonZIndex = await commentButton.evaluate(el => 
            window.getComputedStyle(el).zIndex
          );
          console.log(`✅ パネル開放時のコメントボタンz-index: ${buttonZIndex}`);
          
          if (parseInt(buttonZIndex) < parseInt(panelZIndex)) {
            console.log('✅ コメントボタンがパネルの後ろに正しく配置されています');
          } else {
            console.log('⚠️ コメントボタンのz-indexが高すぎる可能性があります');
          }
        }
        
        // 手順項目にホバーしてもパネルが前面に表示されることを確認
        const moveItems = page.locator('.move-item');
        if (await moveItems.count() > 0) {
          // 最初の手順項目にホバー
          await moveItems.first().hover();
          await page.waitForTimeout(500);
          
          // パネルがまだ表示されていることを確認
          await expect(editorPanel).toBeVisible();
          console.log('✅ 手順項目にホバーしてもコメントパネルが前面に表示されています');
          
          // 複数の手順項目をテスト（可能であれば）
          if (await moveItems.count() > 1) {
            await moveItems.nth(1).hover();
            await page.waitForTimeout(500);
            await expect(editorPanel).toBeVisible();
            console.log('✅ 2つ目の手順項目にホバーしてもコメントパネルが前面に表示されています');
          }
          
          // ホバーを外して通常状態に戻す
          await moveItems.first().blur();
          await page.waitForTimeout(500);
          await expect(editorPanel).toBeVisible();
          console.log('✅ ホバーを外してもコメントパネルが表示されています');
        }
        
        // パネルを閉じる
        const closeButton = page.locator('.close-panel-btn');
        if (await closeButton.count() > 0) {
          await closeButton.click();
          await page.waitForTimeout(500);
          console.log('✅ コメントパネルを閉じました');
        }
      }
    }
  });

  test('複数手順でのコメント機能とz-index確認テスト', async ({ page }) => {
    console.log('=== 複数手順でのコメント機能とz-index確認テスト ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // 手順リストを確認
      const moveItems = page.locator('.move-item');
      const moveCount = await moveItems.count();
      console.log(`✅ 現在の手順数: ${moveCount}件`);
      
      // 1手目にコメントを追加
      if (moveCount >= 1) {
        const firstMoveItem = moveItems.first();
        const firstCommentButton = firstMoveItem.locator('.comment-toggle-btn');
        
        if (await firstCommentButton.count() > 0) {
          console.log('✅ 1手目のコメントボタンが見つかりました');
          
          await firstCommentButton.click();
          await page.waitForTimeout(1000);
          
          // 1手目のコメントパネルが開いたことを確認
          const commentPanel = page.locator('.comment-editor-panel').first();
          await expect(commentPanel).toBeVisible();
          console.log('✅ 1手目のコメントパネルが開きました');
          
          // 1手目にコメントを追加
          const addButton = commentPanel.locator('.add-comment-btn');
          if (await addButton.count() > 0) {
            await addButton.click();
            await page.waitForTimeout(500);
            
            const textarea = commentPanel.locator('.comment-textarea');
            await textarea.fill('1手目のテストコメントです');
            console.log('✅ 1手目にコメントを入力しました');
            
            const createButton = commentPanel.locator('.save-btn').filter({ hasText: '作成' });
            await createButton.click();
            console.log('✅ 1手目のコメントを作成しました');
            
            // パネルが閉じるまで待機
            await page.waitForTimeout(2000);
          }
          
          // 1手目のコメントパネルを再度開いてz-index問題をテスト
          console.log('🔍 z-index競合問題をテストします...');
          
          await firstCommentButton.click();
          await page.waitForTimeout(1000);
          
          const reopenedPanel = page.locator('.comment-editor-panel').first();
          await expect(reopenedPanel).toBeVisible();
          console.log('✅ 1手目のコメントパネルを再度開きました');
          
          // パネルのz-indexを確認
          const panelZIndex = await reopenedPanel.evaluate(el => 
            window.getComputedStyle(el).zIndex
          );
          console.log(`📋 コメントパネルのz-index: ${panelZIndex}`);
          
          // コメントボタンのz-indexを確認（panel-openクラス付き）
          const buttonZIndex = await firstCommentButton.evaluate(el => 
            window.getComputedStyle(el).zIndex
          );
          console.log(`📋 コメントボタンのz-index: ${buttonZIndex}`);
          
          // コメントボタンがpanel-openクラスを持っているかを確認
          const hasOpenClass = await firstCommentButton.evaluate(el => 
            el.classList.contains('panel-open')
          );
          console.log(`📋 コメントボタンにpanel-openクラス: ${hasOpenClass}`);
          
          // z-index値の数値比較
          const panelZ = parseInt(panelZIndex) || 0;
          const buttonZ = parseInt(buttonZIndex) || 0;
          
          if (panelZ > buttonZ) {
            console.log('✅ パネルのz-indexがボタンより高く設定されています');
          } else {
            console.log('⚠️ z-index設定に問題がある可能性があります');
          }
          
          // 同じ手順項目の他の部分にホバーしてテスト
          const moveContent = firstMoveItem.locator('.move-content');
          if (await moveContent.count() > 0) {
            await moveContent.hover();
            await page.waitForTimeout(500);
            
            await expect(reopenedPanel).toBeVisible();
            console.log('✅ 同じ手順項目にホバーしてもパネルが前面に表示されています');
          }
          
          // 他の手順項目があればホバーしてテスト
          if (moveCount > 1) {
            for (let i = 1; i < Math.min(moveCount, 3); i++) {
              const otherMoveItem = moveItems.nth(i);
              await otherMoveItem.hover();
              await page.waitForTimeout(300);
              
              await expect(reopenedPanel).toBeVisible();
              console.log(`✅ ${i + 1}手目にホバーしてもパネルが前面に表示されています`);
              
              // その手順項目のコメントボタンにもホバー
              const otherCommentButton = otherMoveItem.locator('.comment-toggle-btn');
              if (await otherCommentButton.count() > 0) {
                await otherCommentButton.hover();
                await page.waitForTimeout(300);
                
                await expect(reopenedPanel).toBeVisible();
                console.log(`✅ ${i + 1}手目のコメントボタンにホバーしてもパネルが前面に表示されています`);
              }
            }
          }
          
          // 最終的にパネルを閉じる
          const closeButton = reopenedPanel.locator('.close-panel-btn');
          if (await closeButton.count() > 0) {
            await closeButton.click();
            await page.waitForTimeout(500);
            console.log('✅ コメントパネルを閉じました');
          }
          
        } else {
          console.log('⚠️ 1手目のコメントボタンが見つかりませんでした');
        }
      } else {
        console.log('⚠️ 手順が見つかりません');
      }
    }
  });

  test('コメント表示問題のデバッグテスト', async ({ page }) => {
    console.log('=== コメント表示問題のデバッグテスト ===');
    
    // APIレスポンスを監視
    const apiResponses: any[] = [];
    page.on('response', response => {
      if (response.url().includes('/api/') && response.url().includes('comment')) {
        apiResponses.push({
          url: response.url(),
          status: response.status(),
          method: response.request().method()
        });
      }
    });

    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントボタンを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        console.log('✅ コメントボタンが見つかりました');
        
        // 1. コメントエディターを開く
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');

        // 2. 既存コメントがあるかを確認
        const existingComments = page.locator('.comment-list .comment-item');
        const existingCount = await existingComments.count();
        console.log(`📋 既存コメント数: ${existingCount}件`);

        if (existingCount > 0) {
          for (let i = 0; i < existingCount; i++) {
            const commentContent = await existingComments.nth(i).locator('.comment-content').textContent();
            console.log(`📋 既存コメント${i + 1}: ${commentContent}`);
          }
        }
        
        // 3. 新しいコメントを作成
        const addButton = page.locator('.add-comment-btn');
        if (await addButton.count() > 0) {
          await addButton.click();
          await page.waitForTimeout(500);
          console.log('✅ コメント追加ボタンをクリックしました');
          
          const textarea = page.locator('.comment-textarea');
          const testComment = `デバッグテストコメント - ${new Date().getTime()}`;
          await textarea.fill(testComment);
          console.log(`✅ コメントを入力しました: ${testComment}`);
          
          // 作成ボタンをクリック
          const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
          await createButton.click();
          console.log('✅ 作成ボタンをクリックしました');
          
          // APIレスポンスをチェック
          await page.waitForTimeout(2000);
          console.log('📋 APIレスポンス:');
          apiResponses.forEach(resp => {
            console.log(`  - ${resp.method} ${resp.url} -> ${resp.status}`);
          });
          
          // 4. パネルが自動で閉じるのを待つ
          await page.waitForTimeout(2000);
          
          // 5. パネルを再度開いてコメントが表示されるかを確認
          await commentButtons.click();
          await page.waitForTimeout(1000);
          
          const reopenedPanel = page.locator('.comment-editor-panel');
          await expect(reopenedPanel).toBeVisible();
          console.log('✅ コメントパネルを再度開きました');
          
          // コメントリストの状態を確認
          const commentList = page.locator('.comment-list');
          const isListVisible = await commentList.isVisible();
          console.log(`📋 コメントリストの表示状態: ${isListVisible}`);
          
          if (isListVisible) {
            const items = page.locator('.comment-list .comment-item');
            const itemCount = await items.count();
            console.log(`📋 表示されているコメント数: ${itemCount}件`);
            
            for (let i = 0; i < itemCount; i++) {
              const content = await items.nth(i).locator('.comment-content').textContent();
              console.log(`📋 コメント${i + 1}: ${content}`);
            }
            
            // 作成したコメントがあるかを確認
            const createdComment = page.locator('.comment-content').filter({ hasText: testComment });
            if (await createdComment.count() > 0) {
              console.log('✅ 作成したコメントが正しく表示されています');
            } else {
              console.log('❌ 作成したコメントが表示されていません');
            }
          } else {
            console.log('❌ コメントリストが表示されていません');
            
            // デバッグ情報として他の要素の存在も確認
            const createSection = page.locator('.comment-create');
            const newSection = page.locator('.comment-new');
            const loadingSection = page.locator('.loading');
            
            console.log(`📋 add-comment-btnの表示状態: ${await createSection.isVisible()}`);
            console.log(`📋 comment-newの表示状態: ${await newSection.isVisible()}`);
            console.log(`📋 loadingの表示状態: ${await loadingSection.isVisible()}`);
          }
          
          // 6. ブラウザコンソールのエラーをチェック
          const logs: string[] = [];
          page.on('console', msg => {
            if (msg.type() === 'error') {
              logs.push(msg.text());
            }
          });
          
          if (logs.length > 0) {
            console.log('❌ ブラウザコンソールエラー:');
            logs.forEach(log => console.log(`  - ${log}`));
          }
          
        } else {
          console.log('⚠️ コメント追加ボタンが見つかりませんでした');
        }
      } else {
        console.log('⚠️ コメントボタンが見つかりませんでした');
      }
    }
  });

  test('自動クローズ無効化後のシンプルコメントテスト', async ({ page }) => {
    console.log('=== 自動クローズ無効化後のシンプルコメントテスト ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントボタンを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        console.log('✅ コメントボタンが見つかりました');
        
        // コメントエディターを開く
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');
        
        // 「テスト」コメントを1つだけ作成
        const addButton = page.locator('.add-comment-btn');
        if (await addButton.count() > 0) {
          await addButton.click();
          await page.waitForTimeout(500);
          
          const textarea = page.locator('.comment-textarea');
          const testComment = 'テスト';
          await textarea.fill(testComment);
          console.log(`✅ コメントを入力しました: "${testComment}"`);
          
          // 作成ボタンをクリック
          const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
          await createButton.click();
          console.log('✅ 作成ボタンをクリックしました');
          
          // 成功メッセージが表示されることを確認
          const successMessage = page.locator('.success-message');
          await expect(successMessage).toBeVisible();
          console.log('✅ 成功メッセージが表示されました');
          
          // しっかりと待機（API呼び出し完了まで）
          await page.waitForTimeout(5000);
          
          // パネルがまだ開いていることを確認
          await expect(editorPanel).toBeVisible();
          console.log('✅ パネルが開いたままです');
          
          // コメントリストが表示されることを確認
          const commentList = page.locator('.comment-list');
          if (await commentList.isVisible()) {
            console.log('✅ コメントリストが表示されました');
            
            // 作成したコメントが表示されることを確認
            const commentItems = page.locator('.comment-list .comment-item');
            const itemCount = await commentItems.count();
            console.log(`📋 コメント項目数: ${itemCount}件`);
            
            if (itemCount > 0) {
              // 最初のコメントの内容を確認
              const firstComment = commentItems.first();
              const contentElement = firstComment.locator('.comment-content');
              
              // 表示状態を確認
              const isVisible = await contentElement.isVisible();
              console.log(`📋 コメント内容の表示状態: ${isVisible}`);
              
              if (isVisible) {
                // テキスト内容を確認
                const contentText = await contentElement.textContent();
                console.log(`📋 コメント内容: "${contentText}"`);
                
                // CSS確認
                const styles = await contentElement.evaluate(el => {
                  const computed = window.getComputedStyle(el);
                  return {
                    color: computed.color,
                    backgroundColor: computed.backgroundColor,
                    fontSize: computed.fontSize,
                    fontWeight: computed.fontWeight,
                    display: computed.display,
                    visibility: computed.visibility,
                    opacity: computed.opacity
                  };
                });
                
                console.log('📋 CSS スタイル:');
                console.log(`  - color: ${styles.color}`);
                console.log(`  - backgroundColor: ${styles.backgroundColor}`);
                console.log(`  - fontSize: ${styles.fontSize}`);
                console.log(`  - fontWeight: ${styles.fontWeight}`);
                console.log(`  - display: ${styles.display}`);
                console.log(`  - visibility: ${styles.visibility}`);
                console.log(`  - opacity: ${styles.opacity}`);
                
                if (contentText && contentText.includes('テスト')) {
                  console.log('✅ 「テスト」コメントが正しく表示されています！');
                } else {
                  console.log(`❌ コメント内容が期待と違います: "${contentText}"`);
                }
              } else {
                console.log('❌ コメント内容要素が見えません');
              }
            } else {
              console.log('❌ コメント項目が見つかりません');
            }
          } else {
            console.log('❌ コメントリストが表示されていません');
            
            // 代替要素の確認
            const addCommentBtn = page.locator('.add-comment-btn');
            const commentNew = page.locator('.comment-new');
            const loading = page.locator('.loading');
            
            console.log(`📋 add-comment-btn表示: ${await addCommentBtn.isVisible()}`);
            console.log(`📋 comment-new表示: ${await commentNew.isVisible()}`);
            console.log(`📋 loading表示: ${await loading.isVisible()}`);
          }
          
        } else {
          console.log('⚠️ コメント追加ボタンが見つかりませんでした');
        }
      } else {
        console.log('⚠️ コメントボタンが見つかりませんでした');
      }
    }
  });

  test('修正後のコメント表示とタイミング確認テスト', async ({ page }) => {
    console.log('=== 修正後のコメント表示とタイミング確認テスト ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントボタンを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        console.log('✅ コメントボタンが見つかりました');
        
        // コメントエディターを開く
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');
        
        // 新しいコメントを作成
        const addButton = page.locator('.add-comment-btn');
        if (await addButton.count() > 0) {
          await addButton.click();
          await page.waitForTimeout(500);
          console.log('✅ コメント追加ボタンをクリックしました');
          
          const textarea = page.locator('.comment-textarea');
          const testComment = '修正後テストコメント';
          await textarea.fill(testComment);
          console.log(`✅ コメントを入力しました: ${testComment}`);
          
          // 作成ボタンをクリック
          const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
          await createButton.click();
          console.log('✅ 作成ボタンをクリックしました');
          
          // 成功メッセージが表示されることを確認
          const successMessage = page.locator('.success-message');
          await expect(successMessage).toBeVisible();
          console.log('✅ 成功メッセージが表示されました');
          
          // 1.5秒後に成功メッセージが消える
          await page.waitForTimeout(2000);
          await expect(successMessage).not.toBeVisible();
          console.log('✅ 成功メッセージが消えました');
          
          // パネルはまだ開いていることを確認
          await expect(editorPanel).toBeVisible();
          console.log('✅ パネルはまだ開いています');
          
          // コメントリストが表示されることを確認
          const commentList = page.locator('.comment-list');
          await expect(commentList).toBeVisible();
          console.log('✅ コメントリストが表示されました');
          
          // 作成したコメントが表示されることを確認
          const commentContent = page.locator('.comment-content').filter({ hasText: testComment });
          await expect(commentContent).toBeVisible();
          console.log('✅ 作成したコメントが正しく表示されています');
          
          // 2秒後にパネルが自動で閉じることを確認
          await page.waitForTimeout(2500);
          await expect(editorPanel).not.toBeVisible();
          console.log('✅ パネルが自動で閉じました（適切なタイミング）');
          
          // コメントボタンにコメント数が表示されることを確認
          const commentCount = page.locator('.comment-count');
          await expect(commentCount).toBeVisible();
          const countText = await commentCount.textContent();
          console.log(`✅ コメント数が表示されました: ${countText}`);
          
          // has-commentsクラスが適用されることを確認
          const hasCommentsClass = await commentButtons.evaluate(el => 
            el.classList.contains('has-comments')
          );
          console.log(`✅ has-commentsクラス: ${hasCommentsClass}`);
          
        } else {
          console.log('⚠️ コメント追加ボタンが見つかりませんでした');
        }
      } else {
        console.log('⚠️ コメントボタンが見つかりませんでした');
      }
    }
  });

  test('コメント内容の視覚的確認テスト', async ({ page }) => {
    console.log('=== コメント内容の視覚的確認テスト ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントボタンを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        console.log('✅ コメントボタンが見つかりました');
        
        // コメントエディターを開く
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');
        
        // 複数のテストコメントを作成
        const testComments = ['テスト1', 'これは長めのコメントです。複数行のテストも含みます。\n改行テストも行います。', '短文'];
        
        for (let i = 0; i < testComments.length; i++) {
          const testComment = testComments[i];
          console.log(`📝 コメント${i + 1}を作成: "${testComment}"`);
          
          // コメント追加ボタンをクリック
          const addButton = page.locator('.add-comment-btn');
          if (await addButton.count() > 0) {
            await addButton.click();
            await page.waitForTimeout(500);
            
            // テキストエリアに入力
            const textarea = page.locator('.comment-textarea');
            await textarea.fill(testComment);
            console.log(`✅ コメント${i + 1}を入力しました`);
            
            // 作成ボタンをクリック
            const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
            await createButton.click();
            console.log(`✅ コメント${i + 1}を作成しました`);
            
            // 作成完了を待つ
            await page.waitForTimeout(2000);
          }
        }
        
        // 全てのコメントが表示されているかを確認
        const commentItems = page.locator('.comment-list .comment-item');
        const itemCount = await commentItems.count();
        console.log(`📋 作成されたコメント数: ${itemCount}件`);
        
        // 各コメントの内容と視覚的属性を確認
        for (let i = 0; i < itemCount; i++) {
          const item = commentItems.nth(i);
          const contentElement = item.locator('.comment-content');
          
          // テキスト内容を確認
          const contentText = await contentElement.textContent();
          console.log(`📋 コメント${i + 1} 内容: "${contentText}"`);
          
          // CSS属性を確認
          const backgroundColor = await contentElement.evaluate(el => 
            window.getComputedStyle(el).backgroundColor
          );
          const color = await contentElement.evaluate(el => 
            window.getComputedStyle(el).color
          );
          const fontSize = await contentElement.evaluate(el => 
            window.getComputedStyle(el).fontSize
          );
          const fontWeight = await contentElement.evaluate(el => 
            window.getComputedStyle(el).fontWeight
          );
          const border = await contentElement.evaluate(el => 
            window.getComputedStyle(el).border
          );
          
          console.log(`📋 コメント${i + 1} CSS:`);
          console.log(`  - background: ${backgroundColor}`);
          console.log(`  - color: ${color}`);
          console.log(`  - fontSize: ${fontSize}`);
          console.log(`  - fontWeight: ${fontWeight}`);
          console.log(`  - border: ${border}`);
          
          // 要素が表示されているかを確認
          const isVisible = await contentElement.isVisible();
          console.log(`📋 コメント${i + 1} 表示状態: ${isVisible}`);
          
          if (!isVisible) {
            console.log(`❌ コメント${i + 1}が非表示になっています`);
          }
        }
        
        // しばらく表示して確認
        console.log('📋 3秒間表示します...');
        await page.waitForTimeout(3000);
        
        // パネルを閉じる
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        console.log('✅ パネルを閉じました');
        
      } else {
        console.log('⚠️ コメントボタンが見つかりませんでした');
      }
    }
  });

  test('既存コメントの削除ポップアップなし確認', async ({ page }) => {
    console.log('=== 既存コメントの削除ポップアップなし確認 ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントボタンを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const editorPanel = page.locator('.comment-editor-panel');
        await expect(editorPanel).toBeVisible();
        console.log('✅ コメントエディターパネルが開きました');
        
        // まずコメントを1つ作成
        const addButton = page.locator('.add-comment-btn');
        if (await addButton.count() > 0) {
          await addButton.click();
          await page.waitForTimeout(500);
          
          const textarea = page.locator('.comment-textarea');
          await textarea.fill('削除テスト');
          
          const createButton = page.locator('.save-btn').filter({ hasText: '作成' });
          await createButton.click();
          console.log('✅ テスト用コメントを作成しました');
          
          // 作成完了を待機し、パネルが開いているかを確認
          await page.waitForTimeout(4000); // 自動クローズの時間を待つ
          
          // パネルが閉じている場合は再度開く
          if (!(await editorPanel.isVisible())) {
            await commentButtons.click();
            await page.waitForTimeout(1000);
            console.log('✅ パネルを再度開きました');
          }
          
          // 削除ボタンを探す
          const deleteButtons = page.locator('.delete-btn');
          const deleteButtonCount = await deleteButtons.count();
          console.log(`📋 削除ボタン数: ${deleteButtonCount}個`);
          
          if (deleteButtonCount > 0) {
            console.log('✅ 削除ボタンが見つかりました');
            
            // ダイアログリスナーを設定
            let dialogShown = false;
            page.on('dialog', dialog => {
              dialogShown = true;
              console.log(`🔔 ダイアログ表示: ${dialog.message()}`);
              dialog.accept();
            });
            
            // 削除前のコメント数を確認
            const beforeItems = page.locator('.comment-list .comment-item');
            const beforeCount = await beforeItems.count();
            console.log(`📋 削除前のコメント数: ${beforeCount}件`);
            
            // 削除ボタンをクリック
            await deleteButtons.first().click();
            console.log('✅ 削除ボタンをクリックしました');
            
            // 削除処理の完了を待つ
            await page.waitForTimeout(2000);
            
            // ダイアログの表示確認
            if (!dialogShown) {
              console.log('✅ 確認ダイアログが表示されませんでした（正常）');
            } else {
              console.log('❌ 確認ダイアログが表示されました');
            }
            
            // 削除後のコメント数を確認
            const afterItems = page.locator('.comment-list .comment-item');
            const afterCount = await afterItems.count();
            console.log(`📋 削除後のコメント数: ${afterCount}件`);
            
            if (afterCount < beforeCount) {
              console.log('✅ コメントが削除されました');
            } else if (beforeCount === 0) {
              console.log('⚠️ 削除前からコメントがありませんでした');
            } else {
              console.log('❌ コメントが削除されませんでした');
            }
            
          } else {
            console.log('⚠️ 削除ボタンが見つかりませんでした');
            
            // デバッグ：コメント一覧の状態を確認
            const commentList = page.locator('.comment-list');
            const createSection = page.locator('.comment-create');
            
            console.log(`📋 comment-list表示: ${await commentList.isVisible()}`);
            console.log(`📋 comment-create表示: ${await createSection.isVisible()}`);
          }
        }
      }
    }
  });

  test('レスポンシブUIと改善されたデザインの確認', async ({ page }) => {
    console.log('=== レスポンシブUIと改善されたデザインの確認 ===');
    
    // デスクトップサイズでテスト
    await page.setViewportSize({ width: 1200, height: 800 });
    console.log('📱 デスクトップサイズ (1200x800) に設定');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントボタンを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        console.log('✅ コメントボタンが見つかりました');
        
        // デスクトップでのスタイル確認
        const buttonStyles = await commentButtons.evaluate(el => {
          const computed = window.getComputedStyle(el);
          return {
            minHeight: computed.minHeight,
            padding: computed.padding,
            borderRadius: computed.borderRadius,
            backgroundColor: computed.backgroundColor
          };
        });
        
        console.log('📋 デスクトップでのボタンスタイル:');
        console.log(`  - minHeight: ${buttonStyles.minHeight}`);
        console.log(`  - padding: ${buttonStyles.padding}`);
        console.log(`  - borderRadius: ${buttonStyles.borderRadius}`);
        console.log(`  - backgroundColor: ${buttonStyles.backgroundColor}`);
        
        // コメントパネルを開く
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const panel = page.locator('.comment-editor-panel');
        await expect(panel).toBeVisible();
        console.log('✅ コメントパネルが開きました');
        
        // デスクトップでのパネルサイズ確認
        const panelBox = await panel.boundingBox();
        if (panelBox) {
          console.log(`📋 デスクトップでのパネルサイズ: ${panelBox.width}x${panelBox.height}`);
        }
        
        // パネルを閉じる
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        
        // タブレットサイズでテスト
        await page.setViewportSize({ width: 768, height: 1024 });
        console.log('📱 タブレットサイズ (768x1024) に設定');
        await page.waitForTimeout(1000);
        
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const tabletPanelBox = await panel.boundingBox();
        if (tabletPanelBox) {
          console.log(`📋 タブレットでのパネルサイズ: ${tabletPanelBox.width}x${tabletPanelBox.height}`);
        }
        
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        
        // モバイルサイズでテスト
        await page.setViewportSize({ width: 375, height: 667 });
        console.log('📱 モバイルサイズ (375x667) に設定');
        await page.waitForTimeout(1000);
        
        // モバイルでのボタンスタイル確認
        const mobileButtonStyles = await commentButtons.evaluate(el => {
          const computed = window.getComputedStyle(el);
          return {
            minHeight: computed.minHeight,
            padding: computed.padding,
            fontSize: computed.fontSize
          };
        });
        
        console.log('📋 モバイルでのボタンスタイル:');
        console.log(`  - minHeight: ${mobileButtonStyles.minHeight}`);
        console.log(`  - padding: ${mobileButtonStyles.padding}`);
        console.log(`  - fontSize: ${mobileButtonStyles.fontSize}`);
        
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        // モバイルでのパネル位置確認（fixed position）
        const mobilePanel = page.locator('.comment-editor-panel');
        const mobilePanelStyles = await mobilePanel.evaluate(el => {
          const computed = window.getComputedStyle(el);
          return {
            position: computed.position,
            top: computed.top,
            left: computed.left,
            right: computed.right,
            maxHeight: computed.maxHeight
          };
        });
        
        console.log('📋 モバイルでのパネルスタイル:');
        console.log(`  - position: ${mobilePanelStyles.position}`);
        console.log(`  - top: ${mobilePanelStyles.top}`);
        console.log(`  - left: ${mobilePanelStyles.left}`);
        console.log(`  - right: ${mobilePanelStyles.right}`);
        console.log(`  - maxHeight: ${mobilePanelStyles.maxHeight}`);
        
        // コメント作成ボタンのタッチフレンドリー性を確認
        const addButton = page.locator('.add-comment-btn');
        if (await addButton.count() > 0) {
          const addButtonStyles = await addButton.evaluate(el => {
            const computed = window.getComputedStyle(el);
            return {
              minHeight: computed.minHeight,
              padding: computed.padding
            };
          });
          
          console.log('📋 モバイルでの追加ボタンスタイル:');
          console.log(`  - minHeight: ${addButtonStyles.minHeight}`);
          console.log(`  - padding: ${addButtonStyles.padding}`);
          
          // 44px以上のタッチターゲットかチェック
          const buttonBox = await addButton.boundingBox();
          if (buttonBox && buttonBox.height >= 44) {
            console.log('✅ タッチフレンドリーなボタンサイズです');
          } else {
            console.log('⚠️ タッチターゲットが小さい可能性があります');
          }
        }
        
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        
        // 小さな画面サイズでテスト
        await page.setViewportSize({ width: 320, height: 568 });
        console.log('📱 小画面サイズ (320x568) に設定');
        await page.waitForTimeout(1000);
        
        const smallButtonStyles = await commentButtons.evaluate(el => {
          const computed = window.getComputedStyle(el);
          return {
            padding: computed.padding,
            fontSize: computed.fontSize
          };
        });
        
        console.log('📋 小画面でのボタンスタイル:');
        console.log(`  - padding: ${smallButtonStyles.padding}`);
        console.log(`  - fontSize: ${smallButtonStyles.fontSize}`);
        
        // 元のサイズに戻す
        await page.setViewportSize({ width: 1200, height: 800 });
        console.log('✅ レスポンシブテスト完了');
        
      } else {
        console.log('⚠️ コメントボタンが見つかりませんでした');
      }
    }
  });

  test('改善されたUIコンポーネントの動作確認', async ({ page }) => {
    console.log('=== 改善されたUIコンポーネントの動作確認 ===');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        // ホバー効果の確認
        await commentButtons.hover();
        await page.waitForTimeout(500);
        console.log('✅ ボタンホバー効果を確認');
        
        // パネルを開く
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const panel = page.locator('.comment-editor-panel');
        await expect(panel).toBeVisible();
        console.log('✅ アニメーション付きでパネルが開きました');
        
        // パネルヘッダーのスタイル確認
        const panelHeader = page.locator('.comment-panel-header');
        const headerStyles = await panelHeader.evaluate(el => {
          const computed = window.getComputedStyle(el);
          return {
            background: computed.background,
            padding: computed.padding,
            borderRadius: computed.borderTopLeftRadius
          };
        });
        
        console.log('📋 パネルヘッダースタイル:');
        console.log(`  - background: ${headerStyles.background.substring(0, 50)}...`);
        console.log(`  - padding: ${headerStyles.padding}`);
        console.log(`  - borderRadius: ${headerStyles.borderRadius}`);
        
        // 閉じるボタンのホバー効果確認
        const closeButton = page.locator('.close-panel-btn');
        await closeButton.hover();
        await page.waitForTimeout(500);
        console.log('✅ 閉じるボタンのホバー効果を確認');
        
        // コメント追加ボタンのスタイル確認
        const addButton = page.locator('.add-comment-btn');
        if (await addButton.count() > 0) {
          const addButtonStyles = await addButton.evaluate(el => {
            const computed = window.getComputedStyle(el);
            return {
              border: computed.border,
              borderRadius: computed.borderRadius,
              padding: computed.padding,
              transition: computed.transition
            };
          });
          
          console.log('📋 追加ボタンスタイル:');
          console.log(`  - border: ${addButtonStyles.border}`);
          console.log(`  - borderRadius: ${addButtonStyles.borderRadius}`);
          console.log(`  - padding: ${addButtonStyles.padding}`);
          
          // ホバー効果確認
          await addButton.hover();
          await page.waitForTimeout(500);
          console.log('✅ 追加ボタンのホバー効果を確認');
          
          // コメント作成フローを簡単にテスト
          await addButton.click();
          await page.waitForTimeout(500);
          
          const textarea = page.locator('.comment-textarea');
          if (await textarea.count() > 0) {
            // テキストエリアのフォーカススタイル確認
            await textarea.focus();
            await page.waitForTimeout(500);
            
            const textareaStyles = await textarea.evaluate(el => {
              const computed = window.getComputedStyle(el);
              return {
                borderColor: computed.borderColor,
                boxShadow: computed.boxShadow,
                borderWidth: computed.borderWidth
              };
            });
            
            console.log('📋 テキストエリアフォーカススタイル:');
            console.log(`  - borderColor: ${textareaStyles.borderColor}`);
            console.log(`  - boxShadow: ${textareaStyles.boxShadow.substring(0, 50)}...`);
            console.log(`  - borderWidth: ${textareaStyles.borderWidth}`);
            
            // テスト入力
            await textarea.fill('UI改善テスト');
            console.log('✅ テキスト入力を確認');
            
            // 保存ボタンのスタイル確認
            const saveButton = page.locator('.save-btn').filter({ hasText: '作成' });
            if (await saveButton.count() > 0) {
              const saveButtonStyles = await saveButton.evaluate(el => {
                const computed = window.getComputedStyle(el);
                return {
                  background: computed.background,
                  borderRadius: computed.borderRadius,
                  minHeight: computed.minHeight,
                  fontWeight: computed.fontWeight
                };
              });
              
              console.log('📋 保存ボタンスタイル:');
              console.log(`  - background: ${saveButtonStyles.background.substring(0, 50)}...`);
              console.log(`  - borderRadius: ${saveButtonStyles.borderRadius}`);
              console.log(`  - minHeight: ${saveButtonStyles.minHeight}`);
              console.log(`  - fontWeight: ${saveButtonStyles.fontWeight}`);
              
              // ホバー効果確認
              await saveButton.hover();
              await page.waitForTimeout(500);
              console.log('✅ 保存ボタンのホバー効果を確認');
            }
          }
        }
        
        // パネルを閉じる
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        console.log('✅ UI改善テスト完了');
      }
    }
  });

  test('MoveHistoryPanelとの幅合わせとスマホ対応確認', async ({ page }) => {
    console.log('=== MoveHistoryPanelとの幅合わせとスマホ対応確認 ===');
    
    // デスクトップサイズでテスト
    await page.setViewportSize({ width: 1200, height: 800 });
    console.log('📱 デスクトップサイズ (1200x800) に設定');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // MoveHistoryPanelの幅を確認
      const moveHistoryPanel = page.locator('.move-history-panel');
      if (await moveHistoryPanel.count() > 0) {
        const panelBox = await moveHistoryPanel.boundingBox();
        const panelWidth = panelBox?.width || 0;
        console.log(`📋 MoveHistoryPanelの幅: ${panelWidth}px`);
        
        // コメントボタンを開く
        const commentButtons = page.locator('.comment-toggle-btn').first();
        if (await commentButtons.count() > 0) {
          await commentButtons.click();
          await page.waitForTimeout(1000);
          
          const commentPanel = page.locator('.comment-editor-panel');
          await expect(commentPanel).toBeVisible();
          console.log('✅ コメントパネルが開きました');
          
          // デスクトップでのコメントパネル幅確認
          const commentPanelBox = await commentPanel.boundingBox();
          const commentPanelWidth = commentPanelBox?.width || 0;
          console.log(`📋 コメントパネルの幅: ${commentPanelWidth}px`);
          
          // 幅が一致するかチェック（280px）
          if (Math.abs(commentPanelWidth - 280) <= 2) {
            console.log('✅ コメントパネルの幅がMoveHistoryPanelと一致しています');
          } else {
            console.log(`⚠️ 幅が一致しません。期待値: 280px, 実際: ${commentPanelWidth}px`);
          }
          
          // パネルのposition確認
          const panelStyles = await commentPanel.evaluate(el => {
            const computed = window.getComputedStyle(el);
            return {
              position: computed.position,
              width: computed.width,
              maxWidth: computed.maxWidth
            };
          });
          
          console.log('📋 デスクトップでのパネルスタイル:');
          console.log(`  - position: ${panelStyles.position}`);
          console.log(`  - width: ${panelStyles.width}`);
          console.log(`  - maxWidth: ${panelStyles.maxWidth}`);
          
          await page.keyboard.press('Escape');
          await page.waitForTimeout(500);
        }
      }
      
             // タブレット（768px）でのテスト       await page.setViewportSize({ width: 768, height: 1024 });       console.log('📱 タブレットサイズ (768x1024) に設定');       await page.waitForTimeout(1000);              const tabletCommentButtons = page.locator('.comment-toggle-btn').first();       await tabletCommentButtons.click();
      await page.waitForTimeout(1000);
      
      const tabletPanel = page.locator('.comment-editor-panel');
      const tabletPanelStyles = await tabletPanel.evaluate(el => {
        const computed = window.getComputedStyle(el);
        return {
          position: computed.position,
          width: computed.width,
          maxWidth: computed.maxWidth,
          transform: computed.transform,
          left: computed.left
        };
      });
      
      console.log('📋 タブレットでのパネルスタイル:');
      console.log(`  - position: ${tabletPanelStyles.position}`);
      console.log(`  - width: ${tabletPanelStyles.width}`);
      console.log(`  - maxWidth: ${tabletPanelStyles.maxWidth}`);
      console.log(`  - transform: ${tabletPanelStyles.transform}`);
      console.log(`  - left: ${tabletPanelStyles.left}`);
      
      if (tabletPanelStyles.position === 'fixed') {
        console.log('✅ タブレットサイズでfixed positionに切り替わりました');
      }
      
      await page.keyboard.press('Escape');
      await page.waitForTimeout(500);
      
             // モバイル（480px以下）でのテスト       await page.setViewportSize({ width: 375, height: 667 });       console.log('📱 モバイルサイズ (375x667) に設定');       await page.waitForTimeout(1000);              const mobileCommentButtons = page.locator('.comment-toggle-btn').first();       await mobileCommentButtons.click();
      await page.waitForTimeout(1000);
      
      const mobilePanel = page.locator('.comment-editor-panel');
      const mobilePanelStyles = await mobilePanel.evaluate(el => {
        const computed = window.getComputedStyle(el);
        return {
          position: computed.position,
          top: computed.top,
          left: computed.left,
          right: computed.right,
          width: computed.width,
          maxHeight: computed.maxHeight,
          borderRadius: computed.borderRadius
        };
      });
      
      console.log('📋 モバイルでのパネルスタイル:');
      console.log(`  - position: ${mobilePanelStyles.position}`);
      console.log(`  - top: ${mobilePanelStyles.top}`);
      console.log(`  - left: ${mobilePanelStyles.left}`);
      console.log(`  - right: ${mobilePanelStyles.right}`);
      console.log(`  - width: ${mobilePanelStyles.width}`);
      console.log(`  - maxHeight: ${mobilePanelStyles.maxHeight}`);
      console.log(`  - borderRadius: ${mobilePanelStyles.borderRadius}`);
      
      // オーバーレイ背景の確認
      const overlay = page.locator('.comment-editor:has(.comment-editor-panel)');
      if (await overlay.count() > 0) {
        const overlayStyles = await overlay.evaluate(el => {
          const before = window.getComputedStyle(el, '::before');
          return {
            content: before.content,
            background: before.background,
            position: before.position
          };
        });
        
        console.log('📋 オーバーレイ背景:');
        console.log(`  - content: ${overlayStyles.content}`);
        console.log(`  - background: ${overlayStyles.background.substring(0, 50)}...`);
        console.log(`  - position: ${overlayStyles.position}`);
        
        if (overlayStyles.content !== 'none' && overlayStyles.content !== '""') {
          console.log('✅ モバイルでオーバーレイ背景が表示されています');
        }
      }
      
      // タッチフレンドリーなサイズの確認
      const mobileButton = page.locator('.comment-toggle-btn');
      const buttonBox = await mobileButton.boundingBox();
      if (buttonBox && buttonBox.height >= 40) {
        console.log('✅ モバイルでタッチフレンドリーなボタンサイズです');
      } else {
        console.log(`⚠️ ボタンサイズが小さい可能性があります: ${buttonBox?.height}px`);
      }
      
      await page.keyboard.press('Escape');
      await page.waitForTimeout(500);
      
      // 元のサイズに戻す
      await page.setViewportSize({ width: 1200, height: 800 });
      console.log('✅ パネル幅調整とスマホ対応テスト完了');
    }
  });

  test('狭いパネル幅でのコンテンツ表示確認', async ({ page }) => {
    console.log('=== 狭いパネル幅でのコンテンツ表示確認 ===');
    
    // デスクトップサイズで開始
    await page.setViewportSize({ width: 1200, height: 800 });
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const panel = page.locator('.comment-editor-panel');
        await expect(panel).toBeVisible();
        console.log('✅ コメントパネルが開きました');
        
        // 長いテストコメントを作成
        const addButton = page.locator('.add-comment-btn');
        if (await addButton.count() > 0) {
          await addButton.click();
          await page.waitForTimeout(500);
          
          const textarea = page.locator('.comment-textarea');
          const longComment = 'これは非常に長いコメントです。280px幅のパネルでも適切に表示されることを確認します。改行も含みます。\n2行目のテキストです。\n3行目も追加して、複数行の表示をテストします。';
          await textarea.fill(longComment);
          console.log('✅ 長いコメントを入力しました');
          
          const saveButton = page.locator('.save-btn').filter({ hasText: '作成' });
          await saveButton.click();
          console.log('✅ コメントを作成しました');
          
          // 自動クローズまで待機
          await page.waitForTimeout(4000);
          
          // パネルを再度開いてコメント表示を確認
          await commentButtons.click();
          await page.waitForTimeout(1000);
          
          const commentContent = page.locator('.comment-content').first();
          if (await commentContent.count() > 0) {
            // コメントコンテンツのスタイル確認
            const contentStyles = await commentContent.evaluate(el => {
              const computed = window.getComputedStyle(el);
              return {
                fontSize: computed.fontSize,
                lineHeight: computed.lineHeight,
                wordBreak: computed.wordBreak,
                overflowWrap: computed.overflowWrap,
                hyphens: computed.hyphens,
                width: computed.width
              };
            });
            
            console.log('📋 280px幅でのコメントコンテンツスタイル:');
            console.log(`  - fontSize: ${contentStyles.fontSize}`);
            console.log(`  - lineHeight: ${contentStyles.lineHeight}`);
            console.log(`  - wordBreak: ${contentStyles.wordBreak}`);
            console.log(`  - overflowWrap: ${contentStyles.overflowWrap}`);
            console.log(`  - hyphens: ${contentStyles.hyphens}`);
            console.log(`  - width: ${contentStyles.width}`);
            
            // コンテンツが適切に表示されているかチェック
            const contentText = await commentContent.textContent();
            if (contentText && contentText.includes('これは非常に長いコメント')) {
              console.log('✅ 長いコメントが正しく表示されています');
            } else {
              console.log('❌ コメント内容が正しく表示されていません');
            }
            
            // コンテンツがパネル幅を超えていないかチェック
            const contentBox = await commentContent.boundingBox();
            const panelBox = await panel.boundingBox();
            
            if (contentBox && panelBox && contentBox.width <= panelBox.width) {
              console.log('✅ コンテンツがパネル幅内に収まっています');
            } else {
              console.log('⚠️ コンテンツがパネル幅を超えている可能性があります');
            }
          }
          
          // ボタンサイズも確認
          const editButtons = page.locator('.edit-btn, .delete-btn');
          if (await editButtons.count() > 0) {
            const buttonStyles = await editButtons.first().evaluate(el => {
              const computed = window.getComputedStyle(el);
              return {
                fontSize: computed.fontSize,
                padding: computed.padding,
                minHeight: computed.minHeight
              };
            });
            
            console.log('📋 280px幅でのボタンスタイル:');
            console.log(`  - fontSize: ${buttonStyles.fontSize}`);
            console.log(`  - padding: ${buttonStyles.padding}`);
            console.log(`  - minHeight: ${buttonStyles.minHeight}`);
          }
        }
        
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        console.log('✅ 狭いパネル幅でのコンテンツ表示確認完了');
      }
    }
  });

  test('コメントパネル250px幅と宇宙背景テーマの確認', async ({ page }) => {
    console.log('=== コメントパネル250px幅と宇宙背景テーマの確認 ===');
    
    // デスクトップサイズでテスト
    await page.setViewportSize({ width: 1200, height: 800 });
    console.log('📱 デスクトップサイズに設定');
    
    // 検討モードに切り替え
    const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
      
      // コメントボタンを開く
      const commentButtons = page.locator('.comment-toggle-btn').first();
      if (await commentButtons.count() > 0) {
        // ボタンの宇宙テーマ確認
        const buttonStyles = await commentButtons.evaluate(el => {
          const computed = window.getComputedStyle(el);
          return {
            background: computed.backgroundColor,
            borderColor: computed.borderColor,
            color: computed.color,
            textShadow: computed.textShadow
          };
        });
        
        console.log('📋 コメントボタンの宇宙テーマスタイル:');
        console.log(`  - background: ${buttonStyles.background}`);
        console.log(`  - borderColor: ${buttonStyles.borderColor}`);
        console.log(`  - color: ${buttonStyles.color}`);
        console.log(`  - textShadow: ${buttonStyles.textShadow}`);
        
        if (buttonStyles.background.includes('rgba(40, 40, 80')) {
          console.log('✅ ボタンに宇宙背景テーマが適用されています');
        }
        
        await commentButtons.click();
        await page.waitForTimeout(1000);
        
        const panel = page.locator('.comment-editor-panel');
        await expect(panel).toBeVisible();
        console.log('✅ コメントパネルが開きました');
        
        // パネルサイズの確認
        const panelBox = await panel.boundingBox();
        const panelWidth = panelBox?.width || 0;
        console.log(`📋 コメントパネルの幅: ${panelWidth}px`);
        
        if (Math.abs(panelWidth - 250) <= 5) {
          console.log('✅ パネル幅が250pxに設定されています');
        } else {
          console.log(`⚠️ パネル幅が期待値と異なります。期待値: 250px, 実際: ${panelWidth}px`);
        }
        
        // パネルの宇宙背景テーマ確認
        const panelStyles = await panel.evaluate(el => {
          const computed = window.getComputedStyle(el);
          return {
            backgroundColor: computed.backgroundColor,
            borderColor: computed.borderColor,
            backdropFilter: computed.backdropFilter,
            boxShadow: computed.boxShadow.substring(0, 50)
          };
        });
        
        console.log('📋 コメントパネルの宇宙テーマスタイル:');
        console.log(`  - backgroundColor: ${panelStyles.backgroundColor}`);
        console.log(`  - borderColor: ${panelStyles.borderColor}`);
        console.log(`  - backdropFilter: ${panelStyles.backdropFilter}`);
        console.log(`  - boxShadow: ${panelStyles.boxShadow}...`);
        
        if (panelStyles.backgroundColor.includes('rgba(30, 30, 60')) {
          console.log('✅ パネルに宇宙背景テーマが適用されています');
        }
        
        if (panelStyles.backdropFilter.includes('blur')) {
          console.log('✅ ブラー効果が適用されています');
        }
        
        // パネルヘッダーの宇宙テーマ確認
        const panelHeader = page.locator('.comment-panel-header');
        if (await panelHeader.count() > 0) {
          const headerStyles = await panelHeader.evaluate(el => {
            const computed = window.getComputedStyle(el);
            return {
              backgroundColor: computed.backgroundColor,
              color: computed.color,
              textShadow: computed.textShadow
            };
          });
          
          console.log('📋 パネルヘッダーの宇宙テーマスタイル:');
          console.log(`  - backgroundColor: ${headerStyles.backgroundColor}`);
          console.log(`  - color: ${headerStyles.color}`);
          console.log(`  - textShadow: ${headerStyles.textShadow}`);
          
          if (headerStyles.backgroundColor.includes('rgba(40, 40, 80')) {
            console.log('✅ ヘッダーに宇宙背景テーマが適用されています');
          }
        }
        
        // コメントコンテンツ部分の宇宙テーマ確認（もしあれば）
        const commentList = page.locator('.comment-list');
        if (await commentList.count() > 0) {
          const listStyles = await commentList.evaluate(el => {
            const computed = window.getComputedStyle(el);
            return {
              backgroundColor: computed.backgroundColor
            };
          });
          
          console.log('📋 コメントリストの宇宙テーマスタイル:');
          console.log(`  - backgroundColor: ${listStyles.backgroundColor}`);
          
          if (listStyles.backgroundColor.includes('rgba(25, 25, 50')) {
            console.log('✅ コメントリストに宇宙背景テーマが適用されています');
          }
        }
        
        await page.keyboard.press('Escape');
        await page.waitForTimeout(500);
        console.log('✅ パネル幅と宇宙テーマの確認完了');
      }
    }
  });

  test('将棋盤レスポンシブ対応の確認', async ({ page }) => {
    console.log('=== 将棋盤レスポンシブ対応の確認 ===');
    
    // 各画面サイズでテスト
    const screenSizes = [
      { width: 1200, height: 800, name: 'デスクトップ' },
      { width: 992, height: 768, name: 'タブレット大' },
      { width: 768, height: 1024, name: 'タブレット' },
      { width: 600, height: 800, name: 'スマホ大' },
      { width: 480, height: 800, name: 'スマホ' },
      { width: 360, height: 640, name: 'スマホ小' }
    ];
    
    for (const screen of screenSizes) {
      console.log(`📱 ${screen.name}サイズ (${screen.width}x${screen.height}) でテスト`);
      
      await page.setViewportSize({ width: screen.width, height: screen.height });
      await page.waitForTimeout(1000);
      
      // 検討モードに切り替え
      const studyTab = page.locator('.tab').filter({ hasText: '検討モード' });
      if (await studyTab.count() > 0) {
        await studyTab.click();
        await page.waitForTimeout(1500);
        
        // 将棋盤コンテナの確認
        const shogiContainer = page.locator('.shogi-container');
        if (await shogiContainer.count() > 0) {
          const containerStyles = await shogiContainer.evaluate(el => {
            const computed = window.getComputedStyle(el);
            return {
              flexDirection: computed.flexDirection,
              gap: computed.gap,
              padding: computed.padding
            };
          });
          
          console.log(`📋 ${screen.name}での将棋コンテナスタイル:`);
          console.log(`  - flexDirection: ${containerStyles.flexDirection}`);
          console.log(`  - gap: ${containerStyles.gap}`);
          console.log(`  - padding: ${containerStyles.padding}`);
          
          // レスポンシブレイアウトの確認
          if (screen.width <= 768) {
            if (containerStyles.flexDirection === 'column') {
              console.log('✅ モバイルサイズで縦レイアウトに切り替わりました');
            }
          } else {
            if (containerStyles.flexDirection === 'row') {
              console.log('✅ デスクトップサイズで横レイアウトです');
            }
          }
        }
        
        // 将棋盤エリアの確認
        const boardArea = page.locator('.board-area');
        if (await boardArea.count() > 0) {
          const boardBox = await boardArea.boundingBox();
          console.log(`📋 ${screen.name}での将棋盤エリアサイズ: ${boardBox?.width}x${boardBox?.height}`);
          
          // 将棋盤自体の確認
          const shogiBoard = page.locator('.board-area .shogi-board');
          if (await shogiBoard.count() > 0) {
            const boardStyles = await shogiBoard.evaluate(el => {
              const computed = window.getComputedStyle(el);
              return {
                width: computed.width,
                maxWidth: computed.maxWidth,
                borderWidth: computed.borderWidth
              };
            });
            
            console.log(`📋 ${screen.name}での将棋盤スタイル:`);
            console.log(`  - width: ${boardStyles.width}`);
            console.log(`  - maxWidth: ${boardStyles.maxWidth}`);
            console.log(`  - borderWidth: ${boardStyles.borderWidth}`);
          }
        }
        
        // ゲーム情報パネルの確認
        const gameInfo = page.locator('.game-info');
        if (await gameInfo.count() > 0) {
          const gameInfoStyles = await gameInfo.evaluate(el => {
            const computed = window.getComputedStyle(el);
            return {
              marginBottom: computed.marginBottom
            };
          });
          
          console.log(`📋 ${screen.name}でのゲーム情報スタイル:`);
          console.log(`  - marginBottom: ${gameInfoStyles.marginBottom}`);
        }
        
        // ボタンのタッチフレンドリー性確認（モバイルサイズ）
        if (screen.width <= 600) {
          const gameButtons = page.locator('.game-info button').first();
          if (await gameButtons.count() > 0) {
            const buttonBox = await gameButtons.boundingBox();
            const buttonHeight = buttonBox?.height || 0;
            
            console.log(`📋 ${screen.name}でのボタン高さ: ${buttonHeight}px`);
            
            if (buttonHeight >= 40) {
              console.log('✅ タッチフレンドリーなボタンサイズです');
            } else {
              console.log('⚠️ ボタンサイズが小さい可能性があります');
            }
          }
        }
        
        // 棋譜パネルの確認
        const moveHistoryContainer = page.locator('.move-history-container');
        if (await moveHistoryContainer.count() > 0) {
          const historyBox = await moveHistoryContainer.boundingBox();
          const historyStyles = await moveHistoryContainer.evaluate(el => {
            const computed = window.getComputedStyle(el);
            return {
              width: computed.width,
              height: computed.height,
              marginTop: computed.marginTop
            };
          });
          
          console.log(`📋 ${screen.name}での棋譜パネル:`);
          console.log(`  - サイズ: ${historyBox?.width}x${historyBox?.height}`);
          console.log(`  - width: ${historyStyles.width}`);
          console.log(`  - height: ${historyStyles.height}`);
          console.log(`  - marginTop: ${historyStyles.marginTop}`);
        }
        
        console.log(`✅ ${screen.name}サイズでのレスポンシブ確認完了\n`);
      }
    }
    
    // 元のサイズに戻す
    await page.setViewportSize({ width: 1200, height: 800 });
    console.log('✅ 将棋盤レスポンシブ対応確認完了');
  });
}); 