import { test, expect } from '@playwright/test';

test.describe('コメントバックエンド統合テスト', () => {
  let gameId: number;

  test.beforeEach(async ({ page }) => {
    // テスト用ゲーム作成
    const gameResponse = await page.request.post('http://localhost:3000/api/v1/games', {
      data: { 
        game: {
          status: 'active'
        }
      }
    });
    
    expect(gameResponse.ok()).toBeTruthy();
    const gameData = await gameResponse.json();
    gameId = gameData.game_id;
    console.log(`✅ テスト用ゲーム作成: ID=${gameId}`);
  });

  test('コメントCRUD操作の統合テスト', async ({ page }) => {
    console.log('=== コメントCRUD統合テスト開始 ===');
    
    // 1. コメント作成
    const createResponse = await page.request.post(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`, {
      data: {
        comment: {
          content: '統合テスト用コメント'
        }
      }
    });
    
    expect(createResponse.status()).toBe(201);
    const createdComment = await createResponse.json();
    expect(createdComment.content).toBe('統合テスト用コメント');
    expect(createdComment.id).toBeDefined();
    console.log(`✅ コメント作成成功: ID=${createdComment.id}`);
    
    // 2. コメント一覧取得
    const listResponse = await page.request.get(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`);
    expect(listResponse.status()).toBe(200);
    const comments = await listResponse.json();
    expect(comments.length).toBe(1);
    expect(comments[0].content).toBe('統合テスト用コメント');
    console.log(`✅ コメント一覧取得成功: ${comments.length}件`);
    
    // 3. コメント更新
    const updateResponse = await page.request.patch(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments/${createdComment.id}`, {
      data: {
        comment: {
          content: '更新されたコメント'
        }
      }
    });
    
    expect(updateResponse.status()).toBe(200);
    const updatedComment = await updateResponse.json();
    expect(updatedComment.content).toBe('更新されたコメント');
    console.log(`✅ コメント更新成功`);
    
    // 4. 更新後の一覧確認
    const updatedListResponse = await page.request.get(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`);
    expect(updatedListResponse.status()).toBe(200);
    const updatedComments = await updatedListResponse.json();
    expect(updatedComments[0].content).toBe('更新されたコメント');
    console.log(`✅ 更新確認成功`);
    
    // 5. コメント削除
    const deleteResponse = await page.request.delete(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments/${createdComment.id}`);
    expect(deleteResponse.status()).toBe(200);
    console.log(`✅ コメント削除成功`);
    
    // 6. 削除後の一覧確認
    const finalListResponse = await page.request.get(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`);
    expect(finalListResponse.status()).toBe(200);
    const finalComments = await finalListResponse.json();
    expect(finalComments.length).toBe(0);
    console.log(`✅ 削除確認成功: ${finalComments.length}件`);
  });

  test('複数コメント管理テスト', async ({ page }) => {
    console.log('=== 複数コメント管理テスト開始 ===');
    
    const testComments = [
      'この局面について',
      '角交換が有力です',
      '飛車先の歩を突く手もあります'
    ];
    
    // 複数コメント作成
    const createdIds = [];
    for (const content of testComments) {
      const response = await page.request.post(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`, {
        data: {
          comment: { content }
        }
      });
      expect(response.status()).toBe(201);
      const comment = await response.json();
      createdIds.push(comment.id);
    }
    
    // 一覧取得して確認
    const listResponse = await page.request.get(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`);
    expect(listResponse.status()).toBe(200);
    const comments = await listResponse.json();
    expect(comments.length).toBe(3);
    
    // 作成順序の確認（新しいコメントが先頭）
    expect(comments[0].content).toBe('飛車先の歩を突く手もあります');
    expect(comments[1].content).toBe('角交換が有力です');
    expect(comments[2].content).toBe('この局面について');
    
    console.log(`✅ 複数コメント作成・取得成功: ${comments.length}件`);
    
    // 一部コメント削除
    const deleteResponse = await page.request.delete(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments/${createdIds[1]}`);
    expect(deleteResponse.status()).toBe(200);
    
    // 削除後の確認
    const afterDeleteResponse = await page.request.get(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`);
    const afterDeleteComments = await afterDeleteResponse.json();
    expect(afterDeleteComments.length).toBe(2);
    console.log(`✅ 一部削除後確認成功: ${afterDeleteComments.length}件`);
  });

  test('バリデーションエラーテスト', async ({ page }) => {
    console.log('=== バリデーションエラーテスト開始 ===');
    
    // 空のコメント作成を試行
    const emptyResponse = await page.request.post(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments`, {
      data: {
        comment: {
          content: ''
        }
      }
    });
    
    expect(emptyResponse.status()).toBe(422);
    const errorData = await emptyResponse.json();
    expect(errorData.error).toContain("Content can't be blank");
    console.log(`✅ 空コメントエラー確認: ${errorData.error}`);
  });

  test('存在しないリソースのエラーテスト', async ({ page }) => {
    console.log('=== 存在しないリソースエラーテスト開始 ===');
    
    // 存在しないゲームに対するコメント作成
    const response = await page.request.post('http://localhost:3000/api/v1/games/99999/moves/0/comments', {
      data: {
        comment: {
          content: '存在しないゲームへのコメント'
        }
      }
    });
    
    expect(response.status()).toBe(404);
    const errorData = await response.json();
    expect(errorData.error).toContain('指定されたゲームが見つかりません');
    console.log(`✅ 存在しないゲームエラー確認: ${errorData.error}`);
    
    // 存在しないコメントの削除を試行
    const deleteResponse = await page.request.delete(`http://localhost:3000/api/v1/games/${gameId}/moves/0/comments/99999`);
    expect(deleteResponse.status()).toBe(404);
    console.log(`✅ 存在しないコメント削除エラー確認`);
  });
}); 