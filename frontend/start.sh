#!/bin/sh
set -e

# アプリディレクトリへ移動
cd /app

# node_modules の問題を解決
if [ ! -d node_modules ] || [ ! -f node_modules/.package-lock.json ]; then
  echo "Installing or repairing node modules..."
  rm -rf node_modules package-lock.json
  npm cache clean --force
  npm install --no-package-lock
  touch node_modules/.package-lock.json
fi

# rollup モジュールが存在するか確認し、問題があれば再インストール
if [ ! -d node_modules/rollup/dist/es/shared ] || [ ! -f node_modules/rollup/dist/es/shared/rollup.js ]; then
  echo "Fixing rollup module..."
  npm uninstall rollup vite @vitejs/plugin-vue
  npm cache clean --force
  npm install rollup vite@^6.3.3 @vitejs/plugin-vue@^5.2.3 --save-dev --no-package-lock
fi

# ESM スクリプトを実行
echo "Starting Vite (ESM) dev server..."
npm run dev