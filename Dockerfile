FROM alpine:3.15

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

#👇Expectを追加
RUN apk add --no-cache expect

#👇GitHub CLIを追加
RUN apk add --no-cache github-cli

CMD ["bash"]
