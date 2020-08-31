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
        python2 \
        py3-virtualenv \
        py3-pip \
        rsync \
        sed \
        sudo \
        tar \
        unzip \
        zip

# Install dev packages used during pip install phases (mostly headers and python dev tools)
RUN apk --no-cache add --virtual .build-deps \
        python3-dev \
        python2-dev \
        libffi-dev \
        openssl-dev \
        build-base

## Install the Github "pr" CLI to automate github releases
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/testing hub

## Yq will be available as stable in alpine 3.13
RUN apk add --no-cache --repository=http://dl-cdn.alpinelinux.org/alpine/edge/community yq

## Install Terraform from fixed binary distributions
ENV TERRAFORM_VERSION=0.13.1 \
    TERRAFORM_ZIP_SHA256SUM=f7b842d1c06045b496fd00db83520e83a974a294b070dbaf88cb1013c5f02caf
RUN curl -sSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" \
        -o /tmp/terraform.zip \
    && sha256sum /tmp/terraform.zip | grep $TERRAFORM_ZIP_SHA256SUM -q \
    && unzip /tmp/terraform.zip -d /usr/local/bin/ \
    && rm -f /tmp/terraform.zip \
    && terraform -v

## Install Packer from fixed binary distributions
ENV PACKER_VERSION=1.6.1 \
    PACKER_ZIP_SHA256SUM=8dcf97610e8c3907c23e25201dce20b498e1939e89878dec01de6975733c7729
RUN curl -sSL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" \
        -o /tmp/packer.zip \
    && sha256sum /tmp/packer.zip | grep $PACKER_ZIP_SHA256SUM -q \
    && unzip /tmp/packer.zip -d /usr/local/bin/ \
    && rm -f /tmp/packer.zip \
    && packer -v

## Install Mitogen from fixed distribution
ENV MITOGEN_VERSION=0.2.9
RUN curl -sSL "https://networkgenomics.com/try/mitogen-${MITOGEN_VERSION}.tar.gz" -o "/tmp/mitogen-${MITOGEN_VERSION}.tar.gz" \
    && tar -xzf "/tmp/mitogen-${MITOGEN_VERSION}.tar.gz" -C /tmp \
    && rm -rf "/tmp/mitogen-${MITOGEN_VERSION}.tar.gz"

## Default venv (with python3)
ENV VENV_PATH="/venv"
COPY ./dev.pip "${VENV_PATH}/dev.pip"
RUN virtualenv --python=python3 --prompt="(oio-devbox) " "${VENV_PATH}" \
    && source "${VENV_PATH}"/bin/activate \
    && python3 -m pip install --requirement="${VENV_PATH}/dev.pip" \
    && chmod -R 775 "${VENV_PATH}"

COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT ["bash","/entrypoint.sh"]
