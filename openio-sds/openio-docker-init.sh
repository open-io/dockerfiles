#!/bin/bash

# Initialize OpenIO cluster
function initcluster(){
  echo "# Initializing the OpenIO cluster"
  echo "> Starting services"
  /usr/bin/gridinit -d /etc/gridinit.conf >/dev/null 2>&1

  # Default configuration
  NS=OPENIO
  NBREPLICAS=1
  IGNOREDISTANCE=on
  TIMEOUT=20

  echo "> Waiting for the meta1 to register ..."
  etime_start=$(date +"%s")
  etime_end=$(($etime_start + $TIMEOUT))
  nbmeta1=0
  while [ $(date +"%s") -le $etime_end -a $nbmeta1 -lt $NBREPLICAS ]
  do
    sleep 2
    # Count registered meta1
    nbmeta1=$(/usr/bin/oio-cluster -r $NS | grep -c meta1)
  done
  if [ $nbmeta1 -ne $NBREPLICAS ]; then
    echo "Error: Install script did not found $NBREPLICAS meta1 services registered. Return: $nbmeta1"
    exit 1
  fi

  # Initialize meta1 with 3 replicas on the same server
  echo "> Loading meta0 ..."
  /usr/bin/oio-meta0-init -O NbReplicas=$NBREPLICAS -O IgnoreDistance=$IGNOREDISTANCE $NS || \
    (echo "Error: Meta0 init failed. Aborting." ; exit 1)

  # Restarting meta0 and meta1
  echo "> Restarting directory services ..."
  /usr/bin/gridinit_cmd restart @meta0
  /usr/bin/gridinit_cmd restart @meta1

}


### Main

# Clean
/usr/bin/rm -f /run/oio/sds/*

# Firstboot script to setup OpenIO configuration
if [ ! -f /etc/oio/sds/firstboot ]; then
  echo "# Firstboot: Setting up the OpenIO cluster"
  if [ ! -z "${OPENIO_IPADDR}" ]; then
    IPADDR=${OPENIO_IPADDR}
  elif [ ! -z "${OPENIO_IFDEV}" ]; then
    IPADDR=$(/usr/bin/facter "ipaddress_${OPENIO_IFDEV}")
    if [ -z "$IPADDR" ]; then
      echo "Error: Failed to get IP for device ${OPENIO_IFDEV}"
    fi
  fi
  if [ ! -z "$IPADDR" ]; then
    echo "> Using ${IPADDR} IP address for services"
    /usr/bin/find /etc/oio /etc/gridinit.d -type f -print0 | xargs --no-run-if-empty -0 sed -i "s/127.0.0.1/${IPADDR}/g"
  fi

  # Deploy OpenIO
  initcluster

  # Firstboot is done
  touch /etc/oio/sds/firstboot
fi

# Start gridinit if not already started
pkill -0 -F /run/gridinit/gridinit.pid >/dev/null 2>&1 || \
  /usr/bin/gridinit -d /etc/gridinit.conf >/dev/null 2>&1

echo "> Unlocking scores ..."
/usr/bin/sleep 5 && \
  /usr/bin/oio-cluster -r OPENIO | /usr/bin/xargs --no-run-if-empty -n1 /usr/bin/oio-cluster --unlock-score -S >/dev/null 2>&1 && \
  /usr/bin/sleep 5 && \
  /usr/bin/oio-cluster -r OPENIO | /usr/bin/xargs --no-run-if-empty -n1 /usr/bin/oio-cluster --unlock-score -S >/dev/null 2>&1 && \
  bash
