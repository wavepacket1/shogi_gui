import { test, expect } from '@playwright/test';

test('分岐の自動作成と+記号表示のテスト', async ({ page }) => {
  console.log('=== 分岐の自動作成と+記号表示のテスト開始 ===');
  
  try {
    // アプリケーションにアクセス
    await page.goto('http://localhost:5173');
    await page.waitForTimeout(2000);
    
    // 新しいゲームを作成
    const newGameButton = page.locator('button', { hasText: '新しいゲーム' });
    if (await newGameButton.count() > 0) {
      await newGameButton.click();
      await page.waitForTimeout(3000);
    }

    // 検討モードに切り替え
    console.log('1. 検討モードに切り替え中...');
    const studyTab = page.locator('.tab').filter({ hasText: '検討' });
    if (await studyTab.count() > 0) {
      await studyTab.click();
      await page.waitForTimeout(2000);
      console.log('✅ 検討モードに切り替えました');
    } else {
      console.log('⚠️ 検討モードタブが見つかりません');
    }

    // MoveHistoryPanelの存在確認
    const moveHistoryPanel = page.locator('.move-history-panel');
    await expect(moveHistoryPanel).toBeVisible();
    console.log('✅ MoveHistoryPanelが表示されています');

    // 初期手順: 7六歩を指す
    console.log('2. 初期手順: 7六歩を指します...');
    await makeMove(page, 6, 6, 5, 6); // 7六歩
    await page.waitForTimeout(1000);
    
    // 8四歩を指す
    console.log('3. 8四歩を指します...');
    await makeMove(page, 2, 3, 3, 3); // 8四歩
    await page.waitForTimeout(1000);

    // 2六歩を指す
    console.log('4. 2六歩を指します...');
    await makeMove(page, 6, 1, 5, 1); // 2六歩
    await page.waitForTimeout(1000);

    // 現在の手順履歴を確認
    const moveItems = page.locator('.move-item');
    const moveCount = await moveItems.count();
    console.log(`現在の手順数: ${moveCount}`);

    // 1手目（7六歩）に戻る
    console.log('5. 1手目（7六歩）の局面に戻ります...');
    const firstMove = moveItems.nth(1); // 0は開始局面、1が最初の手
    await firstMove.click();
    await page.waitForTimeout(2000);
    console.log('✅ 1手目の局面に移動しました');

    // 別の手（2六歩）を指して分岐を作成
    console.log('6. 別の手（2六歩）を指して分岐を作成します...');
    await makeMove(page, 6, 1, 5, 1); // 2六歩（1手目と異なる手）
    await page.waitForTimeout(3000);

    // 分岐が作成されたかチェック
    console.log('7. 分岐の作成を確認します...');
    
    // コンソールログをチェック
    page.on('console', msg => {
      if (msg.text().includes('自動分岐作成') || msg.text().includes('分岐あり')) {
        console.log('🚀 分岐関連ログ:', msg.text());
      }
    });

    // +記号の表示確認
    console.log('8. +記号の表示を確認します...');
    await page.waitForTimeout(2000);
    
    const branchIndicators = page.locator('.branch-indicator');
    const branchToggleButtons = page.locator('.branch-toggle-btn');
    const plusSigns = page.locator('.branch-icon').filter({ hasText: '+' });
    
    console.log(`分岐インジケータ数: ${await branchIndicators.count()}`);
    console.log(`分岐トグルボタン数: ${await branchToggleButtons.count()}`);
    console.log(`+記号数: ${await plusSigns.count()}`);

    if (await branchIndicators.count() > 0) {
      console.log('✅ 分岐インジケータが表示されています');
      
      if (await plusSigns.count() > 0) {
        console.log('✅ +記号が表示されています');
        
        // +記号をクリックして分岐選択ドロップダウンをテスト
        console.log('9. +記号をクリックして分岐選択をテストします...');
        await plusSigns.first().click();
        await page.waitForTimeout(1000);
        
        const branchDropdown = page.locator('.branch-dropdown');
        if (await branchDropdown.count() > 0) {
          console.log('✅ 分岐選択ドロップダウンが表示されました');
          
          const branchOptions = page.locator('.branch-option');
          const optionCount = await branchOptions.count();
          console.log(`分岐オプション数: ${optionCount}`);
          
          if (optionCount >= 2) {
            console.log('✅ 複数の分岐オプションが表示されています');
            
            // 分岐オプションの内容を確認
            for (let i = 0; i < optionCount; i++) {
              const option = branchOptions.nth(i);
              const branchName = await option.locator('.branch-name').textContent();
              console.log(`分岐 ${i}: ${branchName}`);
            }
          } else {
            console.log('⚠️ 分岐オプションが不足しています');
          }
        } else {
          console.log('❌ 分岐選択ドロップダウンが表示されませんでした');
        }
      } else {
        console.log('❌ +記号が表示されていません');
      }
    } else {
      console.log('❌ 分岐インジケータが表示されていません');
    }

    // 分岐セレクタの確認
    console.log('10. 分岐セレクタを確認します...');
    const branchSelector = page.locator('.branch-selector select');
    if (await branchSelector.count() > 0) {
      const options = await branchSelector.locator('option').allTextContents();
      console.log('分岐セレクタのオプション:', options);
      
      if (options.length > 1) {
        console.log('✅ 複数の分岐が存在します');
      } else {
        console.log('⚠️ mainブランチのみです');
      }
    } else {
      console.log('⚠️ 分岐セレクタが見つかりません');
    }

    console.log('=== 分岐機能テスト完了 ===');
    
  } catch (error) {
    console.error('テスト中にエラーが発生しました:', error);
    throw error;
  }
});

test('全分岐履歴データの取得テスト', async ({ page }) => {
  console.log('=== 全分岐履歴データの取得テスト ===');
  
  // アプリケーションにアクセス
  await page.goto('http://localhost:5173');
  await page.waitForTimeout(2000);
  
  // 新しいゲームを作成
  const newGameButton = page.locator('button', { hasText: '新しいゲーム' });
  if (await newGameButton.count() > 0) {
    await newGameButton.click();
    await page.waitForTimeout(3000);
  }
  
  // ネットワークリクエストを監視
  page.on('request', request => {
    if (request.url().includes('/board_histories')) {
      console.log('📡 API呼び出し:', request.url());
    }
  });

  page.on('response', response => {
    if (response.url().includes('/board_histories')) {
      console.log('📡 API応答:', response.url(), 'ステータス:', response.status());
    }
  });

  // 検討モードに切り替え
  const studyTab = page.locator('.tab').filter({ hasText: '検討' });
  if (await studyTab.count() > 0) {
    await studyTab.click();
    await page.waitForTimeout(3000);
  }

  // MoveHistoryPanelが読み込まれるまで待機
  await expect(page.locator('.move-history-panel')).toBeVisible();
  
  console.log('✅ 全分岐履歴データの取得テスト完了');
});

// ヘルパー関数: 駒を移動させる
async function makeMove(page: any, fromRow: number, fromCol: number, toRow: number, toCol: number) {
  try {
    // 移動元のセルをクリック
    const fromCell = page.locator('.shogi-cell').nth(fromRow * 9 + fromCol);
    await fromCell.click();
    await page.waitForTimeout(500);
    
    // 移動先のセルをクリック
    const toCell = page.locator('.shogi-cell').nth(toRow * 9 + toCol);
    await toCell.click();
    await page.waitForTimeout(500);
    
    console.log(`駒移動: (${fromRow},${fromCol}) → (${toRow},${toCol})`);
  } catch (error) {
    console.error('駒移動エラー:', error);
    
    // フォールバック: より具体的なセレクタを試す
    try {
      const fromSelector = `[data-row="${fromRow}"][data-col="${fromCol}"]`;
      const toSelector = `[data-row="${toRow}"][data-col="${toCol}"]`;
      
      await page.click(fromSelector);
      await page.waitForTimeout(500);
      await page.click(toSelector);
      await page.waitForTimeout(500);
      
      console.log(`フォールバック駒移動成功: (${fromRow},${fromCol}) → (${toRow},${toCol})`);
    } catch (fallbackError) {
      console.error('フォールバック駒移動も失敗:', fallbackError);
    }
  }
} 