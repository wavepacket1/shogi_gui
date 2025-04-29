#!/bin/sh
# 依存関係が足りない場合は再インストール
if [ ! -d "/app/node_modules/vite" ]; then
  echo "Vite not found, installing dependencies..."
  npm install
fi

# package.jsonのdevスクリプトを確認
DEV_SCRIPT=$(grep -o '"dev": *"[^"]*"' package.json | sed 's/"dev": *"\(.*\)"/\1/')
echo "Running: $DEV_SCRIPT --host 0.0.0.0"

# viteを使わずに直接nodeでサーバーを起動
if [ -f "/app/node_modules/vite/bin/vite.js" ]; then
  node /app/node_modules/vite/bin/vite.js --host 0.0.0.0
else
  echo "Trying to reinstall vite..."
  npm uninstall vite
  npm install vite --save-dev
  if [ -f "/app/node_modules/vite/bin/vite.js" ]; then
    node /app/node_modules/vite/bin/vite.js --host 0.0.0.0
  else
    echo "Could not find vite.js even after reinstall"
    exit 1
  fi
fi