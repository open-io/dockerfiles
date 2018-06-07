#!/bin/bash

set -e

export PATH="$PATH:/usr/sbin:/sbin:/bin"

echo "rpi" > /etc/hostname
hostname rpi
echo "root:root" | chpasswd
echo "/dev/mmcblk0p2              /             ext4      defaults              1      1" > /etc/fstab

apt update
DEBIAN_FRONTEND=noninteractive apt install -y lsb-release curl gettext-base openssh-server resolvconf vim console-data

cat << EOF > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF

sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
echo "nameserver 8.8.8.8" > /etc/resolvconf/resolv.conf.d/tail
resolvconf -u
