FROM alpine:3.15

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

#👇Dockerコンテナの作業ルートディレクトリ(今回は'/usr/src/app/')へ秘密鍵をコピー
WORKDIR /usr/src/app/
COPY .ssh/ /usr/src/app/.ssh
RUN chmod 600 /usr/src/app/.ssh/*

CMD ["bash"]
