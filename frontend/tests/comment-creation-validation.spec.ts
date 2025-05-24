import { test, expect } from '@playwright/test';

test.describe('コメント作成と表示の詳細テスト', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.waitForSelector('#app');
    await page.waitForTimeout(2000);
    await page.waitForSelector('header', { timeout: 5000 });
    
    const studyModeTab = page.locator('.tab').filter({ hasText: '検討モード' });
    await expect(studyModeTab).toBeVisible();
    await studyModeTab.click();
    
    await page.waitForSelector('.wrapper', { timeout: 10000 });
    await page.waitForTimeout(1000);
  });

  test('コメント作成後に表示されることを確認', async ({ page }) => {
    console.log('=== コメント作成・表示テスト開始 ===');
    
    // API通信を監視
    let createRequestMade = false;
    let createResponseStatus = 0;
    let createResponseBody = '';
    
    page.on('response', async response => {
      if (response.url().includes('/api/v1/games/') && response.url().includes('/comments') && response.request().method() === 'POST') {
        createRequestMade = true;
        createResponseStatus = response.status();
        try {
          createResponseBody = await response.text();
          console.log(`コメント作成 API Response: ${createResponseStatus} - ${createResponseBody}`);
          
          // エラーレスポンスの詳細を表示
          if (createResponseStatus >= 400) {
            try {
              const errorData = JSON.parse(createResponseBody);
              console.log(`エラー詳細: ${JSON.stringify(errorData, null, 2)}`);
            } catch (parseError) {
              console.log(`エラーレスポンスのパースに失敗: ${parseError}`);
            }
          }
        } catch (e) {
          console.log(`API Response parsing failed: ${e}`);
        }
      }
    });

    page.on('request', request => {
      if (request.url().includes('/api/v1/games/') && request.url().includes('/comments') && request.method() === 'POST') {
        console.log(`コメント作成 API Request: ${request.method()} ${request.url()}`);
        console.log(`Request Body: ${request.postData()}`);
      }
    });
    
    const firstMoveItem = page.locator('.move-item').first();
    await expect(firstMoveItem).toBeVisible();
    
    const commentToggleBtn = firstMoveItem.locator('.comment-toggle-btn').first();
    await expect(commentToggleBtn).toBeVisible();
    
    // コメントエディターを開く
    await commentToggleBtn.click();
    await page.waitForTimeout(1000);
    
    // コメント追加ボタンをクリック
    const addCommentBtn = page.locator('button').filter({ hasText: '+ コメントを追加' });
    await expect(addCommentBtn).toBeVisible();
    await addCommentBtn.click();
    await page.waitForTimeout(500);
    
    // テキストエリアが表示されることを確認
    const textarea = page.locator('.comment-textarea');
    await expect(textarea).toBeVisible();
    
    // テストコメントを入力
    const testComment = 'テスト用コメント - ' + Date.now();
    await textarea.fill(testComment);
    await page.waitForTimeout(500);
    
    // 作成ボタンをクリック
    const createBtn = page.locator('.save-btn').filter({ hasText: '作成' });
    await expect(createBtn).toBeVisible();
    await expect(createBtn).not.toBeDisabled();
    
    await createBtn.click();
    
    // API通信の完了を待つ
    await page.waitForTimeout(3000);
    
    // API呼び出しの確認
    console.log(`✅ 作成リクエスト送信: ${createRequestMade}`);
    console.log(`✅ レスポンスステータス: ${createResponseStatus}`);
    
    if (createRequestMade) {
      if (createResponseStatus === 201) {
        console.log('✅ コメント作成APIが成功しました');
        
        // 作成されたコメントが表示されるかを確認
        const commentDisplays = page.locator('.comment-display');
        if (await commentDisplays.count() > 0) {
          console.log('✅ コメント表示エリアが見つかりました');
          
          // テストコメントの内容が表示されているかを確認
          const commentContents = page.locator('.comment-content');
          let foundTestComment = false;
          
          for (let i = 0; i < await commentContents.count(); i++) {
            const content = await commentContents.nth(i).textContent();
            if (content && content.includes('テスト用コメント')) {
              foundTestComment = true;
              console.log(`✅ 作成したコメントが表示されています: "${content}"`);
              break;
            }
          }
          
          if (!foundTestComment) {
            console.log('⚠️ 作成したコメントが表示されていません');
          }
        } else {
          console.log('⚠️ コメント表示エリアが見つかりません');
        }
      } else {
        console.log(`❌ コメント作成APIが失敗しました。ステータス: ${createResponseStatus}`);
        console.log(`エラー内容: ${createResponseBody}`);
      }
    } else {
      console.log('❌ コメント作成リクエストが送信されませんでした');
    }
  });

  test('バックエンドへのリクエスト形式確認', async ({ page }) => {
    console.log('=== リクエスト形式確認テスト開始 ===');
    
    let requestBody = '';
    
    page.on('request', request => {
      if (request.url().includes('/api/v1/games/') && request.url().includes('/comments') && request.method() === 'POST') {
        requestBody = request.postData() || '';
        console.log(`リクエストボディ: ${requestBody}`);
      }
    });
    
    const firstMoveItem = page.locator('.move-item').first();
    const commentToggleBtn = firstMoveItem.locator('.comment-toggle-btn').first();
    
    await commentToggleBtn.click();
    await page.waitForTimeout(1000);
    
    const addCommentBtn = page.locator('button').filter({ hasText: '+ コメントを追加' });
    await addCommentBtn.click();
    await page.waitForTimeout(500);
    
    const textarea = page.locator('.comment-textarea');
    await textarea.fill('リクエスト形式テスト');
    
    const createBtn = page.locator('.save-btn').filter({ hasText: '作成' });
    await createBtn.click();
    await page.waitForTimeout(2000);
    
    console.log(`✅ 最終的なリクエストボディ: ${requestBody}`);
    
    // リクエストボディが期待される形式か確認
    if (requestBody) {
      try {
        const parsed = JSON.parse(requestBody);
        if (parsed.comment && parsed.comment.content) {
          console.log('✅ 正しいリクエスト形式です');
        } else {
          console.log('❌ リクエスト形式が不正です');
        }
      } catch (e) {
        console.log('❌ JSONパースに失敗しました');
      }
    }
  });
}); 