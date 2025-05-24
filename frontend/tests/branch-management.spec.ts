import { test, expect } from '@playwright/test';

test.describe('分岐管理機能テスト', () => {
  test.beforeEach(async ({ page }) => {
    // アプリのトップページに移動
    await page.goto('/');
    
    // ページが読み込まれるまで待機
    await page.waitForSelector('#app');
    await page.waitForTimeout(1000);
    
    // ヘッダーが表示されるまで待機
    await page.waitForSelector('header', { timeout: 5000 });
    
    console.log('検討モードタブをクリックします...');
    // 検討モードタブをクリック
    const studyModeTab = page.locator('.tab').filter({ hasText: '検討モード' });
    await expect(studyModeTab).toBeVisible();
    await studyModeTab.click();
    
    // 対局開始ボタンをクリックしてゲームを開始
    console.log('対局開始ボタンをクリックします...');
    await page.click('button:has-text("対局開始")');
    await page.waitForTimeout(2000);
    
    // ページのHTMLを取得してデバッグ
    const pageContent = await page.content();
    console.log('ページ読み込み完了。分岐管理UI確認中...');
    
    // 分岐管理UIが表示されるまで待機
    try {
      await page.waitForSelector('.branch-manager', { timeout: 10000 });
      console.log('分岐管理UIが見つかりました');
    } catch (error) {
      console.error('分岐管理UIが見つかりませんでした:', error);
      // 現在表示されている要素をログ出力
      const visibleElements = await page.locator('*').allTextContents();
      console.log('表示されている要素:', visibleElements.slice(0, 10));
    }
  });

  test('分岐管理UIの基本表示確認', async ({ page }) => {
    console.log('分岐管理UIの基本表示確認テスト開始...');
    
    // 分岐管理UIが表示されることを確認
    await expect(page.locator('.branch-manager')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('.branch-header')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('.create-branch-btn')).toBeVisible({ timeout: 5000 });
    
    // 初期状態で「main」分岐が表示されることを確認
    await expect(page.locator('.branch-item').filter({ hasText: 'main' })).toBeVisible({ timeout: 5000 });
    await expect(page.locator('.main-badge')).toBeVisible({ timeout: 5000 });
  });

  test('分岐作成機能のテスト', async ({ page }) => {
    console.log('分岐作成機能テスト開始...');
    
    // 分岐作成ボタンをクリック
    await page.click('.create-branch-btn');
    
    // 分岐作成ダイアログが表示されることを確認
    await expect(page.locator('.dialog-overlay')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('.dialog')).toBeVisible({ timeout: 5000 });
    await expect(page.locator('.dialog-header h5')).toHaveText('新しい分岐を作成');
    
    // 分岐名を入力
    const branchNameInput = page.locator('#branch-name');
    await branchNameInput.fill('test-branch');
    
    // 作成ボタンをクリック
    await page.click('.create-btn');
    
    // ダイアログが閉じることを確認
    await expect(page.locator('.dialog-overlay')).not.toBeVisible({ timeout: 5000 });
    
    // 新しい分岐が一覧に表示されることを確認
    await expect(page.locator('.branch-item').filter({ hasText: 'test-branch' })).toBeVisible({ timeout: 10000 });
  });

  test('分岐切り替え機能のテスト', async ({ page }) => {
    console.log('分岐切り替え機能テスト開始...');
    
    // まず分岐を作成
    await page.click('.create-branch-btn');
    await page.fill('#branch-name', 'switch-test-branch');
    await page.click('.create-btn');
    
    // 分岐一覧で作成した分岐が表示されることを確認
    const newBranch = page.locator('.branch-item').filter({ hasText: 'switch-test-branch' });
    await expect(newBranch).toBeVisible();
    
    // main分岐に戻る
    const mainBranch = page.locator('.branch-item').filter({ hasText: 'main' });
    await mainBranch.click();
    
    // main分岐がアクティブになることを確認
    await expect(mainBranch).toHaveClass(/active/);
    
    // 新しい分岐に切り替え
    await newBranch.click();
    
    // 新しい分岐がアクティブになることを確認
    await expect(newBranch).toHaveClass(/active/);
  });

  test('分岐削除機能のテスト', async ({ page }) => {
    console.log('分岐削除機能テスト開始...');
    
    // 削除用の分岐を作成
    await page.click('.create-branch-btn');
    await page.fill('#branch-name', 'delete-test-branch');
    await page.click('.create-btn');
    
    // 作成した分岐が表示されることを確認
    const targetBranch = page.locator('.branch-item').filter({ hasText: 'delete-test-branch' });
    await expect(targetBranch).toBeVisible();
    
    // 削除ボタンをクリック
    await targetBranch.locator('.delete-btn').click();
    
    // 削除確認ダイアログが表示されることを確認
    await expect(page.locator('.dialog-overlay')).toBeVisible();
    await expect(page.locator('.dialog-header')).toHaveText('分岐削除の確認');
    
    // 削除を実行
    await page.click('.delete-btn-confirm');
    
    // ダイアログが閉じることを確認
    await expect(page.locator('.dialog-overlay')).not.toBeVisible();
    
    // 分岐が一覧から削除されることを確認
    await expect(targetBranch).not.toBeVisible();
  });

  test('main分岐の削除が禁止されることを確認', async ({ page }) => {
    console.log('main分岐削除禁止テスト開始...');
    
    // main分岐には削除ボタンが表示されないことを確認
    const mainBranch = page.locator('.branch-item').filter({ hasText: 'main' });
    await expect(mainBranch.locator('.delete-btn')).not.toBeVisible();
  });

  test('無効な分岐名のバリデーションテスト', async ({ page }) => {
    console.log('分岐名バリデーションテスト開始...');
    
    // 分岐作成ダイアログを開く
    await page.click('.create-branch-btn');
    
    // 無効な文字を含む分岐名を入力
    await page.fill('#branch-name', 'invalid@name');
    
    // エラーメッセージが表示されることを確認
    await expect(page.locator('.error-message')).toBeVisible();
    await expect(page.locator('.error-message')).toHaveText('英数字、ハイフン(-)、アンダースコア(_)のみ使用できます');
    
    // 作成ボタンが無効になることを確認
    await expect(page.locator('.create-btn')).toBeDisabled();
    
    // 有効な分岐名に変更
    await page.fill('#branch-name', 'valid-branch-name');
    
    // エラーメッセージが消えることを確認
    await expect(page.locator('.error-message')).not.toBeVisible();
    
    // 作成ボタンが有効になることを確認
    await expect(page.locator('.create-btn')).not.toBeDisabled();
  });

  test('重複する分岐名のバリデーションテスト', async ({ page }) => {
    console.log('重複分岐名バリデーションテスト開始...');
    
    // 最初の分岐を作成
    await page.click('.create-branch-btn');
    await page.fill('#branch-name', 'duplicate-test');
    await page.click('.create-btn');
    
    // 同じ名前で再度作成を試行
    await page.click('.create-branch-btn');
    await page.fill('#branch-name', 'duplicate-test');
    
    // エラーメッセージが表示されることを確認
    await expect(page.locator('.error-message')).toBeVisible();
    await expect(page.locator('.error-message')).toHaveText('この分岐名は既に存在します');
    
    // 作成ボタンが無効になることを確認
    await expect(page.locator('.create-btn')).toBeDisabled();
  });

  test('キャンセル操作のテスト', async ({ page }) => {
    console.log('キャンセル操作テスト開始...');
    
    // 分岐作成ダイアログを開く
    await page.click('.create-branch-btn');
    await page.fill('#branch-name', 'cancel-test');
    
    // キャンセルボタンをクリック
    await page.click('.cancel-btn');
    
    // ダイアログが閉じることを確認
    await expect(page.locator('.dialog-overlay')).not.toBeVisible();
    
    // 分岐が作成されていないことを確認
    await expect(page.locator('.branch-item').filter({ hasText: 'cancel-test' })).not.toBeVisible();
  });

  test('分岐管理と棋譜表示の連携テスト', async ({ page }) => {
    console.log('分岐管理と棋譜表示連携テスト開始...');
    
    // 棋譜パネルが表示されることを確認
    await expect(page.locator('.move-history-panel')).toBeVisible();
    
    // 分岐を作成
    await page.click('.create-branch-btn');
    await page.fill('#branch-name', 'history-test');
    await page.click('.create-btn');
    
    // 新しい分岐に切り替え
    const newBranch = page.locator('.branch-item').filter({ hasText: 'history-test' });
    await newBranch.click();
    
    // 分岐が切り替わったことを棋譜パネルでも確認
    await expect(newBranch).toHaveClass(/active/);
  });
}); 