FROM fedora:22

MAINTAINER Romain Acciari <romain.acciari@openio.io>

RUN dnf -y install \
    mock \
    git \
    GitPython \
    gpg \
    python-boto \
    python-requests \
    rpm-sign \
    rpmdevtools \
    rpmlint

RUN dnf -y install http://mirror.openio.io/pub/repo/openio/sds/17.04/el/7/x86_64/mock-config-openio-17.04.0-4.el7.oio.noarch.rpm

# /var/lib/mock allows you to access build chroot and packaging result
# /var/cache/mock allows you to use a shared cache on your host
VOLUME ["/var/lib/mock","/var/cache/mock"]

RUN useradd -u 1000 -G mock builder
USER builder

RUN rpmdev-setuptree

COPY build.py /home/builder/

# You should at least specify the SPECFILE environment variable
CMD ["/home/builder/build.py"]
