FROM alpine:3.11

RUN apk add --no-cache \
    bats \
    bash \
    curl \
    docker-cli \
    git \
    python3 \
    py3-pip \
&& apk --no-cache add --virtual \
    .build-deps \
    python3-dev \
    libffi-dev \
    openssl-dev \
    build-base
