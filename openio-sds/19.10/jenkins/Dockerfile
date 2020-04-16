FROM alpine:3.11

RUN apk add --no-cache \
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
    build-base \
&& python3 -m pip install 'ansible<2.10' netaddr

ARG MITOGEN_VERSION=0.2.9
RUN curl -sSL "https://networkgenomics.com/try/mitogen-${MITOGEN_VERSION}.tar.gz" -o "/tmp/mitogen-${MITOGEN_VERSION}.tar.gz" \
    && tar -xzf "/tmp/mitogen-${MITOGEN_VERSION}.tar.gz" -C /tmp \
    && mkdir -p /ansible/plugins \
    && cp -r "/tmp/mitogen-${MITOGEN_VERSION}.tar.gz" /ansible/plugins/ \
    && rm -rf /tmp/mitogen*

COPY ./ansible.cfg /root/.ansible.cfg
