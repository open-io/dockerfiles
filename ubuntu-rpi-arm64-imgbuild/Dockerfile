FROM ubuntu:xenial

MAINTAINER Vladimir DOMBROVSKI (vladimir@openio.io)

RUN \
    apt update -y && apt install -y curl git make gcc gcc-aarch64-linux-gnu dosfstools wget qemu-user-static

RUN \
    mkdir -p /root/src && cd /root/src && \
    wget http://cdimage.ubuntu.com/ubuntu-base/releases/16.04/release/ubuntu-base-16.04.4-base-arm64.tar.gz -O ubuntu.tar.gz && \
    wget https://www.finnie.org/software/raspberrypi/ubuntu-rpi3/20160517-raspi3-arm64-firmware-kernel.tar.xz -O firmware.tar.xz

RUN \
    apt install -y xz-utils binfmt-support qemu qemu-user-static

COPY build.sh /usr/bin/build-image
RUN chmod +x /usr/bin/build-image && \
    mkdir -p /root/mnt/img
COPY mnt/scripts /root/.mnt/scripts

ENTRYPOINT ["/usr/bin/build-image"]
