#!/bin/bash
set -ex

OIOSDS_RELEASE=19.04
DESTINATION=openio/sds:${OIOSDS_RELEASE}

ID=$(docker run --detach --privileged --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro --hostname openiosds centos/systemd:latest /usr/sbin/init)

python3 -m pip install 'ansible<2.8' netaddr
git clone -b ${OIOSDS_RELEASE} https://github.com/open-io/ansible-playbook-openio-deployment.git
cp inventory.yml ansible-playbook-openio-deployment/products/sds
pushd ansible-playbook-openio-deployment/products/sds

#custom inventory
sed -i -e "s@ansible_host: ID@ansible_host: $ID@" inventory.yml


# Download roles
./requirements_install.sh

# Deploy without bootstrap
ansible-playbook -i inventory.yml main.yml --skip-tags checks

if [ $? -eq 0 ]; then
  # Fix redis: remove cluster mode
  ansible openio -i inventory.yml -m shell -a 'sed -i -e "/slaveof/d" /etc/oio/sds/OPENIO/redis-0/redis.conf; rm /etc/gridinit.d/OPENIO-redissentinel-0.conf'
  # Wipe install logs
  ansible openio -i inventory.yml -m shell -a "find /var/log/oio -type f | xargs -n1 cp /dev/null"

  popd
  # Logs to stdout
  ansible node1 -i ansible-playbook-openio-deployment/products/sds/inventory.yml -m copy -a 'src=rsyslog.conf dest=/etc/rsyslog.d/openio-sds.conf mode=0644'

  # Copy entrypoint
  ansible node1 -i ansible-playbook-openio-deployment/products/sds/inventory.yml -m copy -a 'src=openio-docker-init.sh dest=/openio-docker-init.sh mode=0755'

  docker commit --change='CMD ["/openio-docker-init.sh"]' --change "EXPOSE 6000 6001 6006 6007 6009 6011 6014 6017 6110 6120 6200 6300" ${ID} ${DESTINATION}
  docker stop ${ID}
  docker rm ${ID}
fi
