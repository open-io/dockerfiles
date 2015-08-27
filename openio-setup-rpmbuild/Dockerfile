FROM fedora:22
MAINTAINER Romain Acciari <romain.acciari@openio.io>
RUN dnf -y install mock rpmdevtools
RUN useradd -u 1000 -G mock builder
VOLUME ["/var/lib/mock","/var/cache/mock"]
USER builder
RUN rpmdev-setuptree
