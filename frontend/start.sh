#!/bin/sh
set -e

# アプリディレクトリへ移動
cd /app

# node_modules がなければ依存関係をインストール
[ ! -d node_modules ] && npm install

# ESM スクリプトを実行
echo "Starting Vite (ESM) dev server..."
npm run dev