FROM node:18

# 作業ディレクトリの設定
WORKDIR /app

# package.jsonとpackage-lock.jsonをコピー
COPY package*.json ./

# 依存関係のインストール（クリーンインストール）
RUN npm ci --legacy-peer-deps || npm install --no-package-lock

# その他のファイルをコピー
COPY . .
RUN apt-get update -qq && apt-get install -y dos2unix
RUN dos2unix start.sh

# ポートの公開
EXPOSE 5173

# 起動コマンドを明示的に指定
CMD ["/bin/sh", "./start.sh"]
