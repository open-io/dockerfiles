FROM debian:jessie

# Need some packages from backports (for ubuntu/xenial debootstrap support)

VOLUME ["/var/cache/pbuilder"]

RUN mkdir -p /etc/apt/sources.list.d && \
    echo "deb http://httpredir.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/debian-backports.list && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y pbuilder dh-make ubuntu-archive-keyring binfmt-support qemu qemu-user-static && \
    apt-get install -y -t jessie-backports debootstrap devscripts curl && \
    apt-get autoremove -y && \
    rm -rf /var/cache/apt/archives/*.deb

RUN gpg --keyring /usr/share/keyrings/raspbian-archive-keyring.gpg --no-default-keyring --keyserver keys.gnupg.net --recv-key 9165938D90FDDD2E

WORKDIR /root

RUN echo 'DEBEMAIL="ops@openio.io"'              >> .bashrc && \
    echo 'DEBFULLNAME="OpenIO release team"'     >> .bashrc && \
    echo 'export DEBEMAIL DEBFULLNAME'           >> .bashrc && \
    echo "alias l='LANG=C ls -lah --color=auto'" >> .bashrc && \
    mkdir debbuildir

COPY pbuilderrc .pbuilderrc
COPY doit.sh doit.sh

RUN git clone https://github.com/open-io/deb-packaging.git

CMD ./doit.sh
