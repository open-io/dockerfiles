#!/bin/bash

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
OIOSDS_RELEASE="${1}"
OIOSDS_DIR="${CURRENT_DIR}/${1}"

test -n "${1}" || ( echo "Please provide the SDS version as argument." && exit 1 )
test -d "${OIOSDS_DIR}" || ( echo "There is no directory for the provided SDS version (${OIOSDS_DIR})." && exit 1 )

set -eux -o pipefail

DOCKER_BUILD_CONTAINER_NAME="${DOCKER_BUILD_CONTAINER_NAME:-"openio-${OIOSDS_RELEASE}-builder"}"
DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME:-"openio/sds:${OIOSDS_RELEASE}"}"

pushd "${OIOSDS_DIR}"

OIO_DEPLOYMENT_DIR="${OIOSDS_DIR}/ansible-playbook-openio-deployment"

rm -rf "${OIO_DEPLOYMENT_DIR}"
git clone -b "${OIOSDS_RELEASE}" https://github.com/open-io/ansible-playbook-openio-deployment.git "${OIO_DEPLOYMENT_DIR}"

### Inventory selection:
# We check the custom (local) inventory to determine
# the syntax (INI or YAML?), which depends on the version of SDS.
INVENTORY_FILE="inventory.yml"
if [ ! -f "${OIOSDS_DIR}/${INVENTORY_FILE}" ]
then
  INVENTORY_FILE="inventory.ini"
  if [ ! -f "${OIOSDS_DIR}/${INVENTORY_FILE}" ]
  then
    echo "ERROR: Could not find any deployment inventory at ${OIOSDS_DIR}/inventory.yml neither at ${OIOSDS_DIR}/inventory.ini."
    exit 1
  fi
fi

# Overide deployment inventory by the custom one
cp "${OIOSDS_DIR}/${INVENTORY_FILE}" "${OIO_DEPLOYMENT_DIR}/products/sds/${INVENTORY_FILE}"
pushd "${OIO_DEPLOYMENT_DIR}/products/sds"

# Start builder container
docker run --detach --name="${DOCKER_BUILD_CONTAINER_NAME}" --tmpfs=/run --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro --hostname openiosds centos/systemd:latest /usr/sbin/init

rm -rf ansible-playbook-openio-deployment
git clone -b "${OIOSDS_RELEASE}" https://github.com/open-io/ansible-playbook-openio-deployment.git
cp inventory.yml ansible-playbook-openio-deployment/products/sds
pushd ansible-playbook-openio-deployment/products/sds

#custom inventory
sed -i -e "s@ansible_host: ID@ansible_host: ${DOCKER_BUILD_CONTAINER_NAME}@" inventory.yml

# Download roles
./requirements_install.sh

# Deploy without bootstrap
ansible all -m package -a name=iproute

# Deploy without bootstrap
ansible-playbook -i "${INVENTORY_FILE}" main.yml --skip-tags checks -e strategy=mitogen_free

# Fix redis: remove cluster mode
ansible openio -i inventory.yml -m shell -a 'sed -i -e "/slaveof/d" /etc/oio/sds/OPENIO/redis-0/redis.conf; rm /etc/gridinit.d/OPENIO-redissentinel-0.conf'
# Wipe install logs
ansible openio -i inventory.yml -m shell -a "find /var/log/oio -type f | xargs -n1 cp /dev/null"

popd
# Logs to stdout
ansible node1 -i ansible-playbook-openio-deployment/products/sds/inventory.yml -m copy -a 'src=rsyslog.conf dest=/etc/rsyslog.d/openio-sds.conf mode=0644'

# Copy entrypoint
ansible node1 -i ansible-playbook-openio-deployment/products/sds/inventory.yml -m copy -a 'src=openio-docker-init.sh dest=/openio-docker-init.sh mode=0755'

docker commit \
  --change='CMD ["/openio-docker-init.sh"]' \
  --change "EXPOSE 6000 6001 6006 6007 6009 6011 6014 6017 6110 6120 6200 6300" \
  --change='HEALTHCHECK --start-period=5s --retries=30 --interval=10s --timeout=2s CMD bash /usr/local/bin/sds-healthcheck.sh' \
  "${DOCKER_BUILD_CONTAINER_NAME}" "${DOCKER_IMAGE_NAME}"

docker stop "${DOCKER_BUILD_CONTAINER_NAME}"
docker rm -f -v "${DOCKER_BUILD_CONTAINER_NAME}"
