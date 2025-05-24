import { defineConfig, devices } from '@playwright/test';

// TypeScriptの型エラーを回避するための定義
// @ts-ignore
const processEnv = process.env || {};

export default defineConfig({
  testDir: './tests',
  timeout: 30000,
  fullyParallel: false,
  forbidOnly: !!processEnv.CI,
  retries: processEnv.CI ? 2 : 0,
  workers: 1,
  reporter: [['html', { open: 'never' }]],
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
}); 