import { test, expect } from '@playwright/test';

test('モード切替の動作確認', async ({ page }) => {
  // フロントエンドのページを開く
  await page.goto('http://localhost:5173/');
  
  // ページのタイトルを確認
  await expect(page).toHaveTitle(/Vite \+ Vue \+ TS/);

  // メニューバーのタブ要素を取得
  const playModeTab = page.locator('.tab:has-text("対局モード")');
  const editModeTab = page.locator('.tab:has-text("編集モード")');
  const studyModeTab = page.locator('.tab:has-text("検討モード")');

  // 全てのタブが表示されていることを確認
  await expect(playModeTab).toBeVisible();
  await expect(editModeTab).toBeVisible();
  await expect(studyModeTab).toBeVisible();

  // 初期状態のスクリーンショットを撮影
  await page.screenshot({ path: 'frontend/tests/screenshots/initial-state.png', fullPage: true });

  // 対局モードをクリック（初期状態なのでアクティブになる）
  console.log('対局モードタブをクリックします');
  await playModeTab.click();
  await page.waitForTimeout(1000); // 状態変更を待機
  
  // 対局モードがアクティブになっていることを確認
  await expect(playModeTab).toHaveClass(/active/);
  await page.screenshot({ path: 'frontend/tests/screenshots/play-mode.png', fullPage: true });

  // 編集モードに切替
  console.log('編集モードタブをクリックします');
  await editModeTab.click();
  await page.waitForTimeout(1000); // 状態変更を待機
  
  // 編集モードがアクティブになっていることを確認
  await expect(editModeTab).toHaveClass(/active/);
  await expect(playModeTab).not.toHaveClass(/active/);
  await page.screenshot({ path: 'frontend/tests/screenshots/edit-mode.png', fullPage: true });

  // 検討モードに切替
  console.log('検討モードタブをクリックします');
  await studyModeTab.click();
  await page.waitForTimeout(1000); // 状態変更を待機
  
  // 検討モードがアクティブになっていることを確認
  await expect(studyModeTab).toHaveClass(/active/);
  await expect(editModeTab).not.toHaveClass(/active/);
  await expect(playModeTab).not.toHaveClass(/active/);
  await page.screenshot({ path: 'frontend/tests/screenshots/study-mode.png', fullPage: true });

  // 最後に対局モードに戻す
  console.log('対局モードに戻します');
  await playModeTab.click();
  await page.waitForTimeout(1000); // 状態変更を待機
  
  // 対局モードがアクティブになっていることを確認
  await expect(playModeTab).toHaveClass(/active/);
  await expect(studyModeTab).not.toHaveClass(/active/);

  // 最終スクリーンショットを撮影
  await page.screenshot({ path: 'frontend/tests/screenshots/final-state.png', fullPage: true });
});

// UIを確認するための補助テスト
test('フロントエンドのUIを確認', async ({ page }) => {
  // フロントエンドのページを開く
  await page.goto('http://localhost:5173/');
  
  console.log('ページにアクセスしました');
  
  // タイトルを確認
  const title = await page.title();
  console.log('Page Title:', title);
  
  // メニューバーのタブを確認
  const tabs = await page.locator('.tab').all();
  console.log(`ページ上の .tab 要素: ${tabs.length}個`);
  
  for (let i = 0; i < tabs.length; i++) {
    const tabText = await tabs[i].innerText();
    const hasActiveClass = await tabs[i].evaluate(el => el.classList.contains('active'));
    console.log(`Tab ${i + 1}: "${tabText}" ${hasActiveClass ? '(active)' : ''}`);
  }

  // スクリーンショットを撮影
  await page.screenshot({ path: 'frontend/tests/screenshots/ui-check.png', fullPage: true });
  console.log('スクリーンショットを保存しました');
}); 