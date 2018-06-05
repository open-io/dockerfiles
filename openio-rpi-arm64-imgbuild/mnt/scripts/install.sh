#!/bin/bash

set -e

export PATH="$PATH:/usr/sbin:/sbin:/bin"

URL="http://mirror2.openio.io"

echo "rpi-openio" > /etc/hostname
hostname rpi-openio
echo "root:root" | chpasswd
echo "/dev/mmcblk0p2              /             ext4      defaults              1      1" > /etc/fstab

apt update
DEBIAN_FRONTEND=noninteractive apt install -y software-properties-common python-software-properties
add-apt-repository cloud-archive:pike -y || true
apt update
DEBIAN_FRONTEND=noninteractive apt install -y lsb-release curl gettext-base openssh-server resolvconf vim console-data

cat << EOF > /etc/network/interfaces
auto eth0
iface eth0 inet dhcp
EOF

sed -i 's/.*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
echo "deb $URL/pub/repo/openio/sds/17.04/$(lsb_release -i -s)/ $(lsb_release -c -s)/" | tee /etc/apt/sources.list.d/openio-sds.list
echo "nameserver 8.8.8.8" > /etc/resolvconf/resolv.conf.d/tail
resolvconf -u

curl $URL/pub/repo/openio/APT-GPG-KEY-OPENIO-0 | apt-key add -
apt update

apt install -y puppet-module-openio-openiosds

curl -L https://github.com/openstack/puppet-keystone/archive/stable/pike.tar.gz | tar xzf - -C /etc/puppet/modules/
mv /etc/puppet/modules/puppet-keystone-stable-pike /etc/puppet/modules/keystone
curl -L https://github.com/openstack/puppet-openstacklib/archive/stable/pike.tar.gz | tar xzf - -C /etc/puppet/modules/
mv /etc/puppet/modules/puppet-openstacklib-stable-pike /etc/puppet/modules/openstacklib
curl -L https://github.com/openstack/puppet-oslo/archive/stable/pike.tar.gz | tar xzf - -C /etc/puppet/modules/
mv /etc/puppet/modules/puppet-oslo-stable-pike /etc/puppet/modules/oslo
for module in puppetlabs/apache puppetlabs/inifile puppetlabs/stdlib ; do puppet module install $module ; done
