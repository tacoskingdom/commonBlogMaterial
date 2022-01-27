FROM alpine:3.15

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

#👇Expectを追加
RUN apk add --no-cache expect

#👇GitHub CLIを追加
RUN apk add --no-cache github-cli

ENV PS1="[\u@\h:\w]$"

RUN addgroup -g 1000 -S gituser && \
    adduser -D -u 1000 -S -G gituser gituser
RUN echo '%gituser ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

CMD ["bash"]
