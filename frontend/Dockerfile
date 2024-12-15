FROM node:18

# 作業ディレクトリの設定
WORKDIR /app

# パッケージのインストール
COPY package*.json ./
RUN npm install

# アプリケーションコードをコピー
COPY . .

# ポートの公開
EXPOSE 5173

# デフォルトのコマンド
CMD ["npm", "run", "dev"]
