FROM fedora:22
MAINTAINER Romain Acciari <romain.acciari@openio.io>
RUN dnf -y install mock rpmdevtools && useradd -u 1000 -G mock builder
VOLUME ["/var/lib/mock","/var/cache/mock","/home/builder/rpmbuild"]
USER builder
RUN rpmdev-setuptree
