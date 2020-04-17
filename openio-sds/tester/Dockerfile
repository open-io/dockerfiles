FROM alpine:3.11

RUN apk add --no-cache \
    bash \
    bats \
    curl \
    docker-cli \
    git \
    netcat-openbsd \
    redis

ENV BATS_HELPERS_DIR=/bats/helpers

RUN mkdir -p "${BATS_HELPERS_DIR}"
RUN git clone "https://github.com/ztombol/bats-support" "${BATS_HELPERS_DIR}/bats-support"
RUN git clone "https://github.com/ztombol/bats-assert" "${BATS_HELPERS_DIR}/bats-assert"
RUN git clone "https://github.com/ztombol/bats-file" "${BATS_HELPERS_DIR}/bats-file"


COPY ./*.bash "${BATS_HELPERS_DIR}"/
COPY ./checks.bats /tests/checks.bats

ENTRYPOINT ["bats"]
CMD ["/tests/"]
