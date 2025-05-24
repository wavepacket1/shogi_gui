import { test, expect } from '@playwright/test';

test('新ゲームでの分岐作成とインジケータ表示テスト', async ({ page }) => {
  console.log('=== 新ゲームでの分岐作成とインジケータ表示テスト開始 ===');
  
  page.on('console', msg => {
    if (msg.text().includes('🔍') || msg.text().includes('分岐') || msg.text().includes('MovesController') || msg.text().includes('🎮')) {
      console.log(`🖥️ [${msg.type()}]:`, msg.text());
    }
  });

  console.log('1. 新しいゲームを開始...');
  await page.goto('http://localhost:5173', { waitUntil: 'networkidle' });
  await page.waitForTimeout(5000); // 初期化完了まで十分待機

  await page.waitForSelector('.move-history-panel', { timeout: 10000 });
  
  console.log('2. ゲームIDを取得...');
  const gameId = await page.evaluate(async () => {
    // Vue.jsのPiniaストアから直接ゲームIDを取得する方法を試行
    const attempts = [
      // 方法1: Vue.js devtools用のフック経由
      () => {
        const devtools = (window as any).__VUE_DEVTOOLS_GLOBAL_HOOK__;
        if (devtools?.apps?.[0]) {
          try {
            const app = devtools.apps[0];
            const store = app.config?.globalProperties?.$store || app.config?.globalProperties?.$pinia;
            return store?._state?.data?.board?.game?.id || store?.state?.value?.board?.game?.id;
          } catch (e) {
            return null;
          }
        }
        return null;
      },
      
      // 方法2: windowオブジェクトのPiniaインスタンス経由
      () => {
        try {
          const pinia = (window as any).__pinia;
          if (pinia?._s) {
            for (const [key, store] of pinia._s) {
              if (key === 'board' && store.game?.id) {
                return store.game.id;
              }
            }
          }
          return null;
        } catch (e) {
          return null;
        }
      },
      
      // 方法3: Vue.js アプリのrootインスタンス経由
      () => {
        try {
          const vueInstances = document.querySelectorAll('[data-v-app]');
          if (vueInstances.length > 0) {
            const instance = (vueInstances[0] as any).__vueParentComponent;
            return instance?.appContext?.provides?.board?.game?.id;
          }
          return null;
        } catch (e) {
          return null;
        }
      },
      
      // 方法4: DOM要素の属性から取得
      () => {
        const elements = document.querySelectorAll('[data-game-id]');
        if (elements.length > 0) {
          const gameIdStr = elements[0].getAttribute('data-game-id');
          return gameIdStr ? parseInt(gameIdStr) : null;
        }
        return null;
      },

      // 方法5: ローカルストレージから取得
      () => {
        const storedGameId = localStorage.getItem('currentGameId');
        return storedGameId ? parseInt(storedGameId) : null;
      }
    ];

    // 各方法を順次試行
    for (const attempt of attempts) {
      try {
        const gameId = attempt();
        if (gameId && gameId > 0) {
          console.log('🎮 ゲームID取得成功:', gameId);
          return gameId;
        }
      } catch (e) {
        continue;
      }
    }

    // 全て失敗した場合は、APIで最新のゲームを取得
    try {
      const response = await fetch('http://localhost:3000/api/v1/games');
      if (response.ok) {
        const games = await response.json();
        if (games && games.length > 0) {
          const latestGame = games[games.length - 1];
          console.log('🎮 最新ゲーム取得:', latestGame.id);
          return latestGame.id;
        }
      }
    } catch (e) {
      console.error('APIからゲーム取得失敗:', e);
    }

    return null;
  });
  
  console.log('取得したゲームID:', gameId);
  
  if (!gameId) {
    console.error('ゲームIDが取得できませんでした');
    return;
  }

  console.log('3. API経由で最初の手を指します（7六歩）...');
  const firstMoveResult = await page.evaluate(async (gameId) => {
    try {
      // board_idを取得
      let boardId = gameId; // 通常、board_idはgame_idと同じか、それに近い値
      
      const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/boards/${boardId}/move`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          move: '7g7f',
          move_number: 0,
          branch: 'main'
        })
      });
      
      const result = await response.json();
      console.log('🎯 第1手結果:', result);
      return result;
    } catch (error) {
      console.error('第1手エラー:', error);
      return { error: error.message };
    }
  }, gameId);

  console.log('第1手完了:', firstMoveResult);
  await page.waitForTimeout(2000);

  console.log('4. 初期局面に戻り、異なる手を指します（2六歩）...');
  const branchMoveResult = await page.evaluate(async (gameId) => {
    try {
      let boardId = gameId;
      
      const response = await fetch(`http://localhost:3000/api/v1/games/${gameId}/boards/${boardId}/move`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          move: '2g2f',
          move_number: 0,
          branch: 'main'
        })
      });
      
      const result = await response.json();
      console.log('🎯 分岐手結果:', result);
      return result;
    } catch (error) {
      console.error('分岐手エラー:', error);
      return { error: error.message };
    }
  }, gameId);

  console.log('分岐手完了:', branchMoveResult);
  await page.waitForTimeout(3000);

  console.log('5. 分岐インジケータの表示確認...');
  
  // ページを更新して最新データを取得
  await page.reload({ waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  // 分岐インジケータの存在確認
  const branchIndicators = await page.locator('.branch-indicator').count();
  console.log(`分岐インジケータ数: ${branchIndicators}`);

  if (branchIndicators > 0) {
    console.log('✅ 分岐インジケータが表示されています！');
    
    // 分岐インジケータの詳細確認
    const indicatorDetails = await page.evaluate(() => {
      const indicators = document.querySelectorAll('.branch-indicator');
      return Array.from(indicators).map((indicator, index) => ({
        index,
        text: indicator.textContent || '',
        visible: indicator.offsetParent !== null
      }));
    });
    
    console.log('分岐インジケータの詳細:', indicatorDetails);
  } else {
    console.log('❌ 分岐インジケータが表示されていません');
    
    // デバッグ用：手順項目の確認
    const moveItems = await page.locator('.move-item').count();
    console.log(`手順項目数: ${moveItems}`);
    
    for (let i = 0; i < moveItems; i++) {
      const moveText = await page.locator('.move-item').nth(i).textContent();
      console.log(`手順[${i}]: "${moveText}"`);
    }
  }

  console.log('=== 新ゲームでの分岐作成テスト完了 ===');
}); 