FROM alpine:3.11

RUN apk add --no-cache \
    bash \
    bats \
    curl \
    docker-cli \
    netcat-openbsd \
    redis

COPY ./checks.bats /tests/checks.bats

ENTRYPOINT ["bats"]
CMD ["/tests/"]
