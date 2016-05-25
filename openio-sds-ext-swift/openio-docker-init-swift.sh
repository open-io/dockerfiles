#!/bin/bash

# Initialize OpenIO cluster
function setoioproxy(){
  OIOPROXY_IPADDR=$1

  # Check IP argument
  if [ -z "$OIOPROXY_IPADDR" ]; then
    echo "Error: OIOPROXY ipaddress is missing."
    exit 1
  fi
  echo "> Setting $OIOPROXY_IPADDR for OpenIO oioproxy IP address"
#  # Check if IP is valid
#  $IPCALC -s -c "$OIOPROXY_IPADDR"
#  if [ $? -ne 0 ]; then
#    echo "Error: IP $OIOPROXY_IPADDR is invalid."
#    echo "Usage: $0 $1 <ip_address>"
#    exit 1
#  fi

  # Switching vagrant main IP into manifests
  echo "> Using $OIOPROXY_IPADDR IP address to connect to oioproxy"
  /usr/bin/sed -i -e "s/OIOPROXY_IPADDR/${OIOPROXY_IPADDR}/g" /docker-ext-swift.pp

}


### Main

# Firstboot script to setup OpenIO configuration
if [ ! -f /etc/oio/sds/firstboot ]; then
  echo "# Firstboot: Setting up Swift and OIOPROXY IP addresses"
  if [ ! -z "${OPENIO_IPADDR}" ]; then
    IPADDR=${OPENIO_IPADDR}
  elif [ ! -z "${OPENIO_IFDEV}" ]; then
    IPADDR=$(/usr/bin/facter "ipaddress_${OPENIO_IFDEV}")
    if [ -z "$IPADDR" ]; then
      echo "Error: Failed to get IP for device ${OPENIO_IFDEV}"
    fi
  fi
  if [ ! -z "$IPADDR" ]; then
    echo "> Using ${IPADDR} IP address for Swift and KeyStone services"
  else
    IPADDR='127.0.0.1'
  fi

  /usr/bin/sed -i -e "s/OPENIO_IPADDR/${IPADDR}/g" /docker-ext-swift.pp
  /usr/bin/python2 /usr/bin/keystone-all & >/dev/null 2>&1

  setoioproxy $OIOPROXY_IPADDR

  puppet apply --no-stringify_facts --show_diff /docker-ext-swift.pp >/dev/null 2>&1


  # Setting default account
  echo "export OS_TENANT_NAME=demo
export OS_USERNAME=demo
export OS_PASSWORD=DEMO_PASS
export OS_AUTH_URL=http://localhost:5000/v2.0" \
  > ~openio/keystonerc_demo

  # Firstboot is done
  touch /etc/oio/sds/firstboot
fi

# Start services
if [ -z "$(pgrep -f '^/usr/bin/python2 /usr/bin/keystone-all')" ] ; then
  /usr/bin/python2 /usr/bin/keystone-all &
fi
/usr/bin/memcached -d -u memcached -p 11211 -m 64 -c 1024 >/dev/null 2>&1
/usr/bin/gridinit -d /etc/gridinit.conf >/dev/null 2>&1
bash
