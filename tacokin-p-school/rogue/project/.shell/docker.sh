#/bin/sh

# Node.jsのDockerイメージを取得する：
# docker pull node:24-slim

# Node.jsのコンテナーを作成しシェルを起動する：
docker run -it --rm \
    --mount type=bind,src=$(pwd),dst=/usr/src/app \
    -w /usr/src/app \
    -u node:node \
    --entrypoint bash node:24-slim
