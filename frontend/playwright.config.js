// @ts-check
const { defineConfig, devices } = require('@playwright/test');

/**
 * @see https://playwright.dev/docs/test-configuration
 */
module.exports = defineConfig({
  testDir: './src/tests',
  /* 最大タイムアウト */
  timeout: 30 * 1000,
  expect: {
    /**
     * 各アサーションのタイムアウト設定
     */
    timeout: 5000
  },
  /* テスト実行時のレポート設定 */
  reporter: 'html',
  /* ブラウザの設定 */
  use: {
    /* Base URLはテスト時にbaseURLと結合される */
    baseURL: 'http://localhost:5173',
    /* テスト失敗時に自動でスクリーンショットを取得 */
    screenshot: 'only-on-failure',
    /* トレースの取得設定 */
    trace: 'on-first-retry',
  },

  /* テスト実行環境の設定 */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  /* プロセス間での並行実行 */
  fullyParallel: true,
  /* 各ファイルでの並行実行 */
  workers: process.env.CI ? 1 : undefined,
}); 