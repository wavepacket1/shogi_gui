import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath } from 'url'
import { dirname, resolve } from 'path'

const __dirname = dirname(fileURLToPath(import.meta.url))

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src')
    }
  },
  server: {
    watch: {
      usePolling: true // Dockerでのホットリロード対応
    },
    host: true, // コンテナ外からのアクセスを許可
    hmr: {
      host: 'localhost'
    }
  }
})
