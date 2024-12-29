FROM node:18

# 作業ディレクトリの設定
WORKDIR /app

# package.jsonとpackage-lock.jsonをコピー
COPY package*.json ./

# 依存関係のインストール
RUN npm install

# その他のファイルをコピー
COPY . .

# ポートの公開
EXPOSE 5173

# デフォルトのコマンド
CMD ["npm", "run", "dev"]
