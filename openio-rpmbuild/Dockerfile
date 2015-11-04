FROM fedora:22

MAINTAINER Romain Acciari <romain.acciari@openio.io>

RUN dnf -y install mock rpmdevtools git python-requests GitPython

# /var/lib/mock allows you to access build chroot and packaging result
# /var/cache/mock allows you to use a shared cache on your host
VOLUME ["/var/lib/mock","/var/cache/mock"]

RUN useradd -u 1000 -G mock builder
COPY build.py /home/builder/
RUN chown builder /home/builder/build.py
USER builder
RUN rpmdev-setuptree

# You should at least specify the SPECFILE environment variable
CMD ["/home/builder/build.py"]
