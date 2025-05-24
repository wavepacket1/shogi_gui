import { test, expect } from '@playwright/test';

test.describe('コメントAPI直接テスト', () => {
  test('コメント作成APIの直接テスト', async ({ page }) => {
    console.log('=== コメントAPI直接テスト開始 ===');
    
    // ゲーム作成
    const gameResponse = await page.request.post('http://localhost:3000/api/v1/games', {
      data: { 
        game: {
          status: 'active'
        }
      }
    });
    
    console.log(`📤 ゲーム作成レスポンスステータス: ${gameResponse.status()}`);
    if (!gameResponse.ok()) {
      const errorText = await gameResponse.text();
      console.log(`❌ ゲーム作成エラー: ${errorText}`);
    }
    
    expect(gameResponse.ok()).toBeTruthy();
    const gameData = await gameResponse.json();
    const gameId = gameData.game_id;
    console.log(`✅ ゲーム作成成功: ID=${gameId}`);
    
    // コメント作成API直接呼び出し
    const commentData = {
      comment: {
        content: 'API直接テスト用コメント'
      }
    };
    
    console.log(`📤 コメント作成リクエスト送信: POST http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`);
    console.log(`📤 リクエストボディ: ${JSON.stringify(commentData)}`);
    
    const commentResponse = await page.request.post(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`, {
      data: commentData,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log(`📥 レスポンスステータス: ${commentResponse.status()}`);
    
    if (!commentResponse.ok()) {
      const errorText = await commentResponse.text();
      console.log(`❌ エラーレスポンス: ${errorText}`);
    } else {
      const responseData = await commentResponse.json();
      console.log(`✅ 成功レスポンス: ${JSON.stringify(responseData)}`);
    }
    
    expect(commentResponse.ok()).toBeTruthy();
    
    // コメント取得テスト
    const getResponse = await page.request.get(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`);
    expect(getResponse.ok()).toBeTruthy();
    
    const comments = await getResponse.json();
    console.log(`✅ コメント取得成功: ${comments.length}件`);
    expect(comments.length).toBeGreaterThan(0);
  });
  
  test('プロキシ経由でのコメント作成テスト', async ({ page }) => {
    console.log('=== プロキシ経由テスト開始 ===');
    
    // ゲーム作成（プロキシ経由）
    const gameResponse = await page.request.post('http://localhost:5173/api/v1/games', {
      data: { 
        game: {
          status: 'active'
        }
      }
    });
    
    console.log(`📤 ゲーム作成レスポンスステータス（プロキシ経由）: ${gameResponse.status()}`);
    if (!gameResponse.ok()) {
      const errorText = await gameResponse.text();
      console.log(`❌ ゲーム作成エラー（プロキシ経由）: ${errorText}`);
    }
    
    expect(gameResponse.ok()).toBeTruthy();
    const gameData = await gameResponse.json();
    const gameId = gameData.game_id;
    console.log(`✅ ゲーム作成成功（プロキシ経由）: ID=${gameId}`);
    
    // コメント作成（プロキシ経由）
    const commentData = {
      comment: {
        content: 'プロキシ経由テスト用コメント'
      }
    };
    
    console.log(`📤 コメント作成リクエスト送信（プロキシ経由）: POST http://localhost:5173/api/v1/games/${gameId}/moves/0/comments`);
    
    const commentResponse = await page.request.post(`http://localhost:5173/api/v1/games/${gameId}/moves/0/comments`, {
      data: commentData,
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    console.log(`📥 レスポンスステータス（プロキシ経由）: ${commentResponse.status()}`);
    
    if (!commentResponse.ok()) {
      const errorText = await commentResponse.text();
      console.log(`❌ エラーレスポンス（プロキシ経由）: ${errorText}`);
    } else {
      const responseData = await commentResponse.json();
      console.log(`✅ 成功レスポンス（プロキシ経由）: ${JSON.stringify(responseData)}`);
    }
    
    expect(commentResponse.ok()).toBeTruthy();
  });
}); 