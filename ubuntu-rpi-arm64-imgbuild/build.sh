#!/bin/bash

set -e

SRC_DIR=/root/src
MNT_DIR=/root/mnt
IMG_DIR=/root/.mnt/img
SCRIPT_DIR=/root/.mnt/scripts
IMG_NAME=ubuntu_xenial_arm64_rpi.img

BOOT_SIZE=25
TOTAL_SIZE=500

function do_allocate() {
    dd if=/dev/zero of=$IMG_DIR/$IMG_NAME bs=${TOTAL_SIZE}K count=1024
    echo -e "o\nn\np\n1\n\n+${BOOT_SIZE}M\nt\nc\na\nn\np\n2\n\n\nw" | fdisk $IMG_DIR/$IMG_NAME
}

function do_mount() {
    losetup -o $((512*2048)) --sizelimit $((512*(2047 + $BOOT_SIZE*2048))) /dev/loop1 $IMG_DIR/$IMG_NAME
    losetup -o $((512*(2048 + $BOOT_SIZE*2048))) /dev/loop2 $IMG_DIR/$IMG_NAME
    if [ $# -eq 1 ];  then
        mkfs.vfat /dev/loop1
        mkfs.ext4 /dev/loop2
    fi
    mount /dev/loop1 $MNT_DIR/boot
    mount /dev/loop2 $MNT_DIR/root
}

function start() {
    mkdir -p $SRC_DIR $MNT_DIR $IMG_DIR $MNT_DIR/boot $MNT_DIR/root
}

function do_copy() {
    cd $SRC_DIR
    tar xf $SRC_DIR/ubuntu.tar.gz -C $MNT_DIR/root
    mkdir -p $SRC_DIR/fw
    tar xf $SRC_DIR/firmware.tar.xz -C $SRC_DIR/fw
    cd $SRC_DIR/fw
    cp boot/firmware/* $MNT_DIR/boot/ && \
    cp -r lib/* $MNT_DIR/root/lib/
}

function cleanup() {
    umount /dev/loop1 /dev/loop2 || true
    losetup -d /dev/loop1 /dev/loop2 || true
    rm -rf $SRC_DIR/firmware || true
}

function do_chroot() {
    cp /usr/bin/qemu-aarch64-static $MNT_DIR/root/usr/bin/
    cp -av /etc/resolv.conf $MNT_DIR/root/etc/resolv.conf
    update-binfmts --enable qemu-aarch64

    mkdir -p $MNT_DIR/root/root/scripts
    cp -r $SCRIPT_DIR/* $MNT_DIR/root/root/scripts/

    cat << EOF > $MNT_DIR/root/etc/rc.local
#!/bin/sh -e
bash /root/scripts/resize_p1.sh
EOF

    chroot $MNT_DIR/root qemu-aarch64-static /bin/bash /root/scripts/install.sh
}

trap cleanup EXIT

start
do_allocate
do_mount 1
do_copy
do_chroot
