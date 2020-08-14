# This image defines the environement used by the CI
FROM alpine:3.12 AS base-image

## Install Tools using Alpine native packages
RUN apk add --no-cache \
        bash \
        bats \
        ca-certificates \
        coreutils \
        curl \
        docker-cli \
        git \
        make \
        openssh-client \
        openssl \
        py3-virtualenv \
        py3-pip \
        python2 \
        rsync \
        sed \
        sudo \
        tar \
        unzip \
        zip \
    && apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing hub \
    && apk --no-cache add --virtual .build-deps \
        python3-dev \
        libffi-dev \
        openssl-dev \
        build-base

## Install tools from specific binary distributions
ENV TERRAFORM_VERSION=0.13.0 \
    TERRAFORM_ZIP_SHA256SUM=9ed437560faf084c18716e289ea712c784a514bdd7f2796549c735d439dbe378
RUN curl -sSL https://releases.hashicorp.com/terraform/0.13.0/terraform_0.13.0_linux_amd64.zip \
        -o /tmp/terraform.zip \
    && sha256sum /tmp/terraform.zip | grep $TERRAFORM_ZIP_SHA256SUM -q \
    && unzip /tmp/terraform.zip -d /usr/local/bin/ \
    && rm -f /tmp/terraform.zip \
    && terraform -v

## Install tools with python's pip (both OpenIO distribution's pip file + dev tools)
ENV VENV_PATH="/venv" \
    MITOGEN_VERSION=0.2.9
RUN curl -sSL "https://networkgenomics.com/try/mitogen-${MITOGEN_VERSION}.tar.gz" -o "/tmp/mitogen-${MITOGEN_VERSION}.tar.gz" \
    && tar -xzf "/tmp/mitogen-${MITOGEN_VERSION}.tar.gz" -C /tmp \
    && rm -rf "/tmp/mitogen-${MITOGEN_VERSION}.tar.gz"
RUN virtualenv --python=python3 --prompt="(oio-devbox) " "${VENV_PATH}" \
    && source "${VENV_PATH}"/bin/activate \
    && python3 -m pip install 'molecule==3.0.*' docker pytest testinfra yamllint \
    && chmod -R 775 "${VENV_PATH}"

## Entrypoint
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["bash","/entrypoint.sh"]
