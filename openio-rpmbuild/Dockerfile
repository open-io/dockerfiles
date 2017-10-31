FROM fedora:22

MAINTAINER Romain Acciari <romain.acciari@openio.io>

ARG OIO_REPO_HOST="mirror2.openio.io"
ARG OIO_REPO_PORT="80"
ARG OIO_COMPANY="openio"
ARG OIO_PROD="sds"
ARG OIO_PROD_VER="17.04"
ARG OIO_DISTRO="centos"
ARG OIO_DISTRO_VER="7"
ARG OIO_ARCH="x86_64"

ENV REPO_OPENIO http://${OIO_REPO_HOST}:${OIO_REPO_PORT}/pub/repo/${OIO_COMPANY}/${OIO_PROD}/${OIO_PROD_VER}/${OIO_DISTRO}/${OIO_DISTRO_VER}/${OIO_ARCH}
ENV PKG_MOCK_CONFIG mock-config-openio-${OIO_PROD_VER}.0-4.el${OIO_DISTRO_VER}.oio.noarch.rpm

RUN dnf -y update && \
    dnf -y install \
    mock \
    git \
    GitPython \
    gpg \
    python-boto \
    python-requests \
    rpm-sign \
    rpmdevtools \
    rpmlint

RUN dnf -y install ${REPO_OPENIO}/${PKG_MOCK_CONFIG}

# /var/lib/mock allows you to access build chroot and packaging result
# /var/cache/mock allows you to use a shared cache on your host
VOLUME ["/var/lib/mock","/var/cache/mock"]

RUN useradd -u 1000 -G mock builder
USER builder

RUN rpmdev-setuptree

COPY build.py /home/builder/

# You should at least specify the SPECFILE environment variable
CMD ["/home/builder/build.py"]
