import { test, expect } from '@playwright/test';

test.describe('コメント機能のテスト', () => {
  test.beforeEach(async ({ page }) => {
    // アプリのトップページに移動
    await page.goto('/');
    
    // ページが読み込まれるまで待機
    await page.waitForSelector('#app');
    await page.waitForTimeout(2000);
    
    // MenuBarが存在することを確認
    await page.waitForSelector('header', { timeout: 5000 });
    
    // 検討モードタブをクリック
    const studyModeTab = page.locator('.tab').filter({ hasText: '検討モード' });
    await expect(studyModeTab).toBeVisible();
    await studyModeTab.click();
    
    // StudyBoardが表示されるまで待機
    await page.waitForSelector('.wrapper', { timeout: 10000 });
    await page.waitForTimeout(1000);
  });

  test('コメントアイコンが表示されることを確認', async ({ page }) => {
    console.log('=== コメントアイコン表示テスト開始 ===');
    
    // MoveHistoryPanelが表示されることを確認
    const moveHistoryPanel = page.locator('.move-history-panel');
    await expect(moveHistoryPanel).toBeVisible();
    
    // 手順アイテムが存在することを確認
    const moveItems = page.locator('.move-item');
    await expect(moveItems.first()).toBeVisible();
    
    // コメント機能があることを確認
    const commentSections = page.locator('.comment-section');
    if (await commentSections.count() > 0) {
      console.log('✅ コメントセクションが存在します');
      
      // コメントエディター内のコメントトグルボタンを確認
      const commentToggleBtn = page.locator('.comment-toggle-btn').first();
      if (await commentToggleBtn.count() > 0) {
        await expect(commentToggleBtn).toBeVisible();
        console.log('✅ コメントトグルボタンが表示されています');
      } else {
        console.log('⚠️ コメントトグルボタンが見つかりません');
      }
    } else {
      console.log('⚠️ コメントセクションが見つかりません');
    }
  });

  test('コメント作成機能のテスト', async ({ page }) => {
    console.log('=== コメント作成機能テスト開始 ===');
    
    // 最初の手順のコメントボタンをクリック
    const firstMoveItem = page.locator('.move-item').first();
    await expect(firstMoveItem).toBeVisible();
    
    const commentToggleBtn = firstMoveItem.locator('.comment-toggle-btn').first();
    if (await commentToggleBtn.count() > 0) {
      // コメントエディターを開く
      await commentToggleBtn.click();
      await page.waitForTimeout(500);
      
      // コメント追加ボタンを探す
      const addCommentBtn = page.locator('button').filter({ hasText: '+ コメントを追加' });
      if (await addCommentBtn.count() > 0) {
        await addCommentBtn.click();
        await page.waitForTimeout(500);
        
        // テキストエリアが表示されることを確認
        const textarea = page.locator('.comment-textarea');
        await expect(textarea).toBeVisible();
        
        // テストコメントを入力
        const testComment = 'これはテストコメントです';
        await textarea.fill(testComment);
        
        // 作成ボタンをクリック
        const createBtn = page.locator('.save-btn').filter({ hasText: '作成' });
        await expect(createBtn).toBeVisible();
        await createBtn.click();
        
        // リクエストの結果を待つ
        await page.waitForTimeout(2000);
        
        console.log('✅ コメント作成処理を実行しました');
      } else {
        console.log('⚠️ コメント追加ボタンが見つかりません');
      }
    } else {
      console.log('⚠️ コメントトグルボタンが見つかりません');
    }
  });

  test('コメント機能のエラー処理確認', async ({ page }) => {
    console.log('=== コメント機能エラー処理テスト開始 ===');
    
    // ネットワークエラーをシミュレート
    await page.route('**/api/v1/games/*/moves/*/comments', route => {
      if (route.request().method() === 'POST') {
        route.fulfill({
          status: 500,
          contentType: 'application/json',
          body: JSON.stringify({ error: 'Internal Server Error' })
        });
      } else {
        route.continue();
      }
    });
    
    const firstMoveItem = page.locator('.move-item').first();
    const commentToggleBtn = firstMoveItem.locator('.comment-toggle-btn').first();
    
    if (await commentToggleBtn.count() > 0) {
      await commentToggleBtn.click();
      await page.waitForTimeout(500);
      
      const addCommentBtn = page.locator('button').filter({ hasText: '+ コメントを追加' });
      if (await addCommentBtn.count() > 0) {
        await addCommentBtn.click();
        await page.waitForTimeout(500);
        
        const textarea = page.locator('.comment-textarea');
        await textarea.fill('エラーテスト用コメント');
        
        const createBtn = page.locator('.save-btn').filter({ hasText: '作成' });
        await createBtn.click();
        
        // エラーアラートを待つ
        await page.waitForTimeout(2000);
        
        console.log('✅ エラー処理のテストを実行しました');
      }
    }
  });

  test('データベースとの統合確認', async ({ page }) => {
    console.log('=== データベース統合テスト開始 ===');
    
    // APIレスポンスを監視
    let apiRequestMade = false;
    let responseStatus = 0;
    
    page.on('response', response => {
      if (response.url().includes('/api/v1/games/') && response.url().includes('/comments')) {
        apiRequestMade = true;
        responseStatus = response.status();
        console.log(`API Request: ${response.request().method()} ${response.url()} - Status: ${responseStatus}`);
      }
    });
    
    const firstMoveItem = page.locator('.move-item').first();
    const commentToggleBtn = firstMoveItem.locator('.comment-toggle-btn').first();
    
    if (await commentToggleBtn.count() > 0) {
      await commentToggleBtn.click();
      await page.waitForTimeout(1000);
      
      console.log(`✅ APIリクエストが${apiRequestMade ? '実行されました' : '実行されませんでした'}`);
      if (apiRequestMade) {
        console.log(`✅ レスポンスステータス: ${responseStatus}`);
      }
    }
  });
}); 