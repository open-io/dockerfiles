#!/bin/bash

# Default configuration
NS='OPENIO'
NBREPLICAS=1
IGNOREDISTANCE='on'
TIMEOUT=20

# Initialize OpenIO cluster
function initcluster(){
  echo "# Initializing the OpenIO cluster"

  echo "> Starting services"
  /usr/bin/gridinit -d /etc/gridinit.conf >/dev/null 2>&1

  echo "> Waiting for the services to start ..."
  etime_start=$(date +"%s")
  etime_end=$(($etime_start + $TIMEOUT))
  nbmeta1=0
  while [ $(date +"%s") -le $etime_end -a $nbmeta1 -lt $NBREPLICAS ]
  do
    sleep 2
    # Count registered meta1
    nbmeta1=$(/usr/bin/openio --oio-ns=$NS cluster list meta1 -f value -c Id|wc -l)
  done
  if [ $nbmeta1 -ne $NBREPLICAS ]; then
    echo "Error: Install script did not found $NBREPLICAS meta1 services registered. Return: $nbmeta1"
    exit 1
  fi
  etime_start=$(date +"%s")
  etime_end=$(($etime_start + $TIMEOUT))
  score=0
  while [ $(date +"%s") -le $etime_end -a $score -eq 0 ]
  do
    /usr/bin/openio --oio-ns=$NS cluster unlockall >/dev/null 2>&1
    sleep 5
    score=$(/usr/bin/openio --oio-ns=$NS cluster list meta1 -f value -c Score || echo 0)
  done
  if [ $score -eq 0 ]; then
    echo "Error: Unlocking scores failed. Unable to bootstrap namespace. Return: Meta1 score = $score"
    exit 1
  fi

  # Initialize meta1 with 3 replicas on the same server
  echo "> Bootstrapping directory ..."
  /usr/bin/openio --oio-ns=$NS directory bootstrap --replicas $NBREPLICAS || \
    (echo "Error: Directory bootstrap failed. Aborting." ; exit 1)

  # Stopping services
  echo "> Stopping services ..."
  gridinit_pid=$(cat /run/gridinit/gridinit.pid)
  kill "$gridinit_pid" >/dev/null 2>&1
  /usr/bin/timeout "30s" tail --pid="$gridinit_pid" -f /dev/null || kill -s 9 "$gridinit_pid"

}

function unlock(){
  echo "> Unlocking scores ..."
  etime_start=$(date +"%s")
  etime_end=$(($etime_start + $TIMEOUT))
  nbscore=1
  while [ $(date +"%s") -le $etime_end -a $nbscore -gt 0 ]
  do
    /usr/bin/openio --oio-ns=$NS cluster unlockall >/dev/null 2>&1
    sleep 5
    nbscore=$(/usr/bin/openio --oio-ns=$NS cluster list -f value -c Score|grep -c -e '^0$')
  done
  if [ $nbscore -gt 0 ]; then
    echo "Error: Unlocking scores failed."
    exit 1
  fi
}

function gridinit_start(){
  echo "> Starting services ..."
  pkill -0 -F /run/gridinit/gridinit.pid >/dev/null 2>&1 || \
    exec /usr/bin/gridinit /etc/gridinit.conf
}

function set_unlock(){
  sed -i -e "/^\[type:/a lock_at_first_register=false" /etc/oio/sds/*/conscience-*/conscience-*-services.conf
}

function prepare(){
  /usr/bin/rm -f /run/oio/sds/*
  mkdir -p /run/oio/sds
  chown openio.openio /run/oio /run/oio/sds
  chmod 750 /run/oio /run/oio/sds
  mkdir -p /var/lib/oio/sds/OPENIO/{beanstalkd-0,coredump,ecd-0,meta0-0,meta1-0,meta2-0,rawx-0,rdir-0,redis-0}
  chown openio.openio /var/lib/oio/sds/OPENIO /var/lib/oio/sds/OPENIO/{beanstalkd-0,coredump,ecd-0,meta0-0,meta1-0,meta2-0,rawx-0,rdir-0,redis-0}
}

function enable_log(){
  if [ ! -z "$LOG_ENABLED" ]; then
    echo 'Enabling local logs'
    echo '$AddUnixListenSocket /dev/log' >>/etc/rsyslog.conf
    /usr/sbin/rsyslogd
  fi
}

### Main

prepare
enable_log

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

  # Update listenning address
  if [ ! -z "$IPADDR" ]; then
    echo "> Using ${IPADDR} IP address for services"
    /usr/bin/find /etc/oio /etc/gridinit.d -type f -print0 | xargs --no-run-if-empty -0 sed -i "s/127.0.0.1/${IPADDR}/g"
  fi

  # Deploy OpenIO
  initcluster

  # Unlock services
  set_unlock

  # Firstboot is done
  touch /etc/oio/sds/firstboot
fi

# Start gridinit
gridinit_start
