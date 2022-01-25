FROM alpine:3.15

RUN apk update && apk upgrade && \
    apk add --no-cache bash git openssh

CMD ["bash"]
