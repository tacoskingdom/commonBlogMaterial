#/bin/sh

# Node.jsのDockerイメージを取得する：
# docker pull node:24-slim

# Node.jsのコンテナーを作成しシェルを起動する：
docker run -it --rm \
    --mount type=bind,src=$(pwd),dst=/usr/src/app \
    -w /usr/src/app \
    -u node:node \
    -p 5173:5173 \
    --entrypoint bash node:24-slim
