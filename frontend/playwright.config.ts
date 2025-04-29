import { defineConfig, devices } from '@playwright/test';

// TypeScriptの型エラーを回避するための定義
// @ts-ignore
const processEnv = process.env || {};

export default defineConfig({
  testDir: './tests',
  timeout: 30000,
  fullyParallel: true,
  forbidOnly: !!processEnv.CI,
  retries: processEnv.CI ? 2 : 0,
  workers: processEnv.CI ? 1 : undefined,
  reporter: 'html',
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