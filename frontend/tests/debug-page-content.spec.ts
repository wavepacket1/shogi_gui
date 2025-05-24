import { test, expect } from '@playwright/test';

test('ページ内容デバッグ', async ({ page }) => {
  console.log('=== ページ内容デバッグ開始 ===');
  
    console.log('1. ゲーム1876にstudyモードでアクセス...');  await page.goto('http://localhost:5173?game_id=1876&mode=study');  await page.waitForTimeout(5000);

  console.log('2. ページ全体のHTMLダンプ...');
  const pageContent = await page.content();
  console.log('ページの長さ:', pageContent.length);

  console.log('3. MoveHistoryPanelの確認...');
  const moveHistoryPanel = page.locator('.move-history-panel');
  if (await moveHistoryPanel.count() > 0) {
    console.log('MoveHistoryPanelが見つかりました');
    const panelHTML = await moveHistoryPanel.innerHTML();
    console.log('Panel HTML (最初の500文字):', panelHTML.substring(0, 500));
  } else {
    console.log('MoveHistoryPanelが見つかりません');
  }

  console.log('4. BranchManagerの詳細確認...');
  const branchManager = page.locator('.branch-manager');
  const branchManagerCount = await branchManager.count();
  console.log('BranchManager数:', branchManagerCount);

  if (branchManagerCount > 0) {
    const managerHTML = await branchManager.innerHTML();
    console.log('BranchManager HTML:', managerHTML);
  }

  console.log('5. すべてのボタンを確認...');
  const allButtons = page.locator('button');
  const buttonCount = await allButtons.count();
  console.log('ページ内のボタン数:', buttonCount);

  for (let i = 0; i < Math.min(buttonCount, 10); i++) {
    const button = allButtons.nth(i);
    const buttonText = await button.textContent();
    const buttonClass = await button.getAttribute('class');
    console.log(`ボタン${i}: "${buttonText}" (class: ${buttonClass})`);
  }

    console.log('6. mode属性とコンソールログの確認...');    // ブラウザのコンソールログを取得  const consoleLogs = [];  page.on('console', msg => consoleLogs.push(msg.text()));    await page.reload();  await page.waitForTimeout(3000);    console.log('ブラウザコンソールログ (最新10件):');  const recentLogs = consoleLogs.slice(-10);  recentLogs.forEach((log, i) => console.log(`Log${i}: ${log}`));    const modeElements = page.locator('[mode], [data-mode], .mode-study, .mode-edit, .mode-play');  const modeCount = await modeElements.count();  console.log('モード関連要素数:', modeCount);  for (let i = 0; i < modeCount; i++) {    const element = modeElements.nth(i);    const tagName = await element.evaluate(el => el.tagName);    const attributes = await element.evaluate(el => {      const attrs = {};      for (let attr of el.attributes) {        attrs[attr.name] = attr.value;      }      return attrs;    });    console.log(`モード要素${i}: ${tagName}`, attributes);  }

  console.log('7. 分岐・ツリー関連文字列の検索...');
  const treeKeywords = ['ツリー', 'tree', '分岐', 'branch', '🌳'];
  for (const keyword of treeKeywords) {
    const elements = page.locator(`text=${keyword}`);
    const count = await elements.count();
    if (count > 0) {
      console.log(`"${keyword}"を含む要素が${count}個見つかりました`);
    }
  }

  console.log('=== ページ内容デバッグ完了 ===');
}); 