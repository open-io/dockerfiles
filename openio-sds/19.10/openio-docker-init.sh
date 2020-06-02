#!/bin/sh

# Default configuration
NS='OPENIO'
NBREPLICAS=1
TIMEOUT=20

function prepare(){
  mkdir /run/gridinit
  install -d -o openio -g openio -m 750 /run/oio/sds/OPENIO/
}

function update_swift_credentials(){
  if [ ! -z "${SWIFT_CREDENTIALS}" ]; then
    # Remove default credentials
    sed -i -e '/user_demo_demo = DEMO_PASS .member/d' \
      /etc/oio/sds/OPENIO/oioswift-0/proxy-server.conf
    # Add credentials to the Swift proxy configuration
    IFS=',' read -r -a swiftcreds <<< "${SWIFT_CREDENTIALS}"
    for creds in "${swiftcreds[@]}"
    do
      echo "> Adding Openstack Swift credentials $creds"
      IFS=':' read -r -a cred <<< "$creds"
      sed -i -e "s@^use = egg:oioswift#tempauth\$@use = egg:oioswift#tempauth\nuser_${cred[0]}_${cred[1]} = ${cred[2]} ${cred[3]}@" \
        /etc/oio/sds/OPENIO/oioswift-0/proxy-server.conf
      if [ "${creds}" == "${swiftcreds[0]}" ]; then
        sed -i -e "s@aws_access_key_id = demo:demo@aws_access_key_id = ${cred[0]}:${cred[1]}@" /root/.aws/credentials
        sed -i -e "s@aws_secret_access_key = DEMO_PASS@aws_secret_access_key = ${cred[2]}@" /root/.aws/credentials
        AKEY="${cred[0]}:${cred[1]}"
				SKEY="${cred[2]}"
      fi
    done
  else
    AKEY="demo:demo"
    SKEY="DEMO_PASS"
  fi
}

function set_region(){
  if [ ! -z "${REGION}" ]; then
    echo "> Change S3 region"
    sed -i -e "s@location = us-east-1@location = ${REGION}@" /etc/oio/sds/OPENIO/oioswift-0/proxy-server.conf
    sed -i -e "s@region = us-east-1@region = ${REGION}@" /root/.aws/config
  else
    REGION="us-east-1"
  fi
}

function set_workers(){
  if [ ! -z "${WORKERS}" ]; then
    echo "> Change S3 workers"
    sed -i -e "s@workers = 1@workers = ${WORKERS}@" /etc/oio/sds/OPENIO/oioswift-0/proxy-server.conf
  else
    WORKERS="1"
  fi
}

function add_meta2(){
  if [ ! -z "${SUPPL_M2}" ]; then
    echo "> Add supplementaries meta2"
    for i in $(seq 1 $SUPPL_M2); do
      # meta2
      install -d -o openio -g openio -m 755 /var/lib/oio/sds/OPENIO/meta2-$i
      cp -a -r /etc/oio/sds/OPENIO/meta2-0/ /etc/oio/sds/OPENIO/meta2-${i}
      mv /etc/oio/sds/OPENIO/meta2-${i}/meta2-0.conf /etc/oio/sds/OPENIO/meta2-${i}/meta2-${i}.conf
      cp -a /etc/gridinit.d/OPENIO-meta2-0.conf /etc/gridinit.d/OPENIO-meta2-${i}.conf
      sed -i \
        -e "s/meta2-0/meta2-$i/g" -e "s/6120/$((6120 + $i))/" \
        -e "s/OPENIO,meta2,0/OPENIO,meta2,$i/" \
        /etc/gridinit.d/OPENIO-meta2-$i.conf
      cp -a /etc/oio/sds/OPENIO/watch/meta2-0.yml /etc/oio/sds/OPENIO/watch/meta2-$i.yml
      sed -i \
        -e "s/meta2-0/meta2-$i/g" \
        -e "s/6120/$((6120 + $i))/" \
        -e "s@location: openiosds.0@location: openiosds.$i@" \
        /etc/oio/sds/OPENIO/watch/meta2-$i.yml

      # rdir
      install -d -o openio -g openio -m 755 /var/lib/oio/sds/OPENIO/rdir-$i
      sed -i \
        -e "s@location: openiosds.1@location: openiosds.0@" \
        /etc/oio/sds/OPENIO/watch/rdir-0.yml
      install -d -o openio -g openio -m 755  /var/lib/oio/sds/OPENIO/rdir-$i
      cp -a -r /etc/oio/sds/OPENIO/rdir-0/ /etc/oio/sds/OPENIO/rdir-${i}
      mv /etc/oio/sds/OPENIO/rdir-${i}/rdir-0.conf /etc/oio/sds/OPENIO/rdir-${i}/rdir-${i}.conf
      sed -i \
        -e "s/6300/$((6300 + $i))/" \
        -e "s/rdir-0/rdir-$i/" -e "s/rdir,0/rdir,$i/" \
        /etc/oio/sds/OPENIO/rdir-${i}/rdir-${i}.conf
      cp -a /etc/gridinit.d/OPENIO-rdir-0.conf /etc/gridinit.d/OPENIO-rdir-${i}.conf
      sed -i \
        -e "s/rdir-0/rdir-$i/g" \
        -e "s/6300/$((6300 + $i))/" \
        -e "s/OPENIO,rdir,0/OPENIO,rdir,$i/" \
        /etc/gridinit.d/OPENIO-rdir-$i.conf
      cp -a /etc/oio/sds/OPENIO/watch/rdir-0.yml /etc/oio/sds/OPENIO/watch/rdir-$i.yml
      sed -i \
        -e "s/rdir-0/rdir-$i/g" \
        -e "s/6300/$((6300 + $i))/" \
        -e "s@location: openiosds.0@location: openiosds.$i@" \
        /etc/oio/sds/OPENIO/watch/rdir-$i.yml

    done

  fi
}

# Initialize OpenIO cluster
function initcluster(){
  echo "# Initializing the OpenIO cluster"

  # Temporarily disabling the swift gateway, to avoid answering when not completely setup
  sed -i -e 's/^enabled=.*$/enabled=false/' /etc/gridinit.d/OPENIO-oioswift-0.conf

	rm /etc/oio/sds/OPENIO/conscience-0/conscience-0-persistence.dat
  echo "> Starting services"
  /usr/bin/gridinit -d /etc/gridinit.conf >/dev/null 2>&1

  echo "> Waiting for the services to start ..."
  etime_start=$(date +"%s")
  etime_end=$((${etime_start} + ${TIMEOUT}))
  nbmeta1=0
  while [ $(date +"%s") -le ${etime_end} -a ${nbmeta1} -lt ${NBREPLICAS} ]
  do
    sleep 2
    # Count registered meta1
    nbmeta1=$(/usr/bin/openio --oio-ns=${NS} cluster list meta1 -f value -c Addr|wc -l)
  done
  if [ ${nbmeta1} -ne ${NBREPLICAS} ]; then
    echo "Error: Install script did not found ${NBREPLICAS} meta1 services registered. Return: ${nbmeta1}"
    exit 1
  fi
  etime_start=$(date +"%s")
  etime_end=$((${etime_start} + ${TIMEOUT}))
  score=0
  while [ $(date +"%s") -le ${etime_end} -a ${score} -eq 0 ]
  do
    /usr/bin/openio --oio-ns=${NS} cluster unlockall >/dev/null 2>&1
    sleep 5
    score=$(/usr/bin/openio --oio-ns=${NS} cluster list meta1 -f value -c Score || echo 0)
  done
  if [ ${score} -eq 0 ]; then
    echo "Error: Unlocking scores failed. Unable to bootstrap namespace. Return: Meta1 score = ${score}"
    exit 1
  fi

  # Initialize meta1 with 3 replicas on the same server
  echo "> Bootstrapping directory ..."
  /usr/bin/openio --oio-ns=${NS} directory bootstrap --replicas ${NBREPLICAS} || \
    (echo "Error: Directory bootstrap failed. Aborting." ; exit 1)

  echo "> Bootstrapping Reverse Directory and rawx for namespace ${NS}"
  /usr/bin/openio --oio-ns=${NS} rdir bootstrap rawx ||
    (echo "Error: Directory bootstrap failed. Aborting." ; exit 1)
  echo "> Bootstrapping Reverse Directory and meta2 for namespace ${NS}"
  /usr/bin/openio --oio-ns=${NS} rdir bootstrap meta2 ||
    (echo "Error: Directory bootstrap failed. Aborting." ; exit 1)

  # Stopping services
  echo "> Stopping services ..."
  gridinit_pid=$(cat /run/gridinit/gridinit.pid)
  kill "${gridinit_pid}" >/dev/null 2>&1
  /usr/bin/timeout "30s" tail --pid="${gridinit_pid}" -f /dev/null || kill -s 9 "${gridinit_pid}"

}

function set_unlock(){
  sed -i -e "/^\[type:/a lock_at_first_register=false" /etc/oio/sds/*/conscience-*/conscience-*-services.conf
}

function unlock(){
  echo "> Unlocking scores ..."
  etime_start=$(date +"%s")
  etime_end=$((${etime_start} + ${TIMEOUT}))
  nbscore=1
  while [ $(date +"%s") -le ${etime_end} -a ${nbscore} -gt 0 ]
  do
    /usr/bin/openio --oio-ns=${NS} cluster unlockall >/dev/null 2>&1
    sleep 5
    nbscore=$(/usr/bin/openio --oio-ns=${NS} cluster list -f value -c Score|grep -c -e '^0$')
  done
  if [ ${nbscore} -gt 0 ]; then
    echo "Error: Unlocking scores failed."
    exit 1
  fi
}

function gridinit_start(){
  echo "> Starting services ..."
  pkill -0 -F /run/gridinit/gridinit.pid >/dev/null 2>&1 || \
    exec /usr/bin/gridinit /etc/gridinit.conf
}

function keystone_config(){
  if [ ! -z "$KEYSTONE_ENABLED" ]; then
    echo "Setting up Openstack Keystone authentication"
    : "${KEYSTONE_URI:=${IPADDR}:5000}"
    : "${KEYSTONE_URL:=${IPADDR}:35357}"
    : "${SWIFT_USERNAME:=swift}"
    : "${SWIFT_PASSWORD:=SWIFT_PASS}"
    sed -i -e "/filter:tempauth/i [filter:s3token]\ndelay_auth_decision = True\nauth_uri = http://${KEYSTONE_URL}/\nuse = egg:swift3#s3token\n\n[filter:authtoken]\nauth_type = password\nusername = ${SWIFT_USERNAME}\nproject_name = service\nregion_name = ${REGION}\nuser_domain_id = default\nmemcache_secret_key = memcache_secret_key\npaste.filter_factory = keystonemiddleware.auth_token:filter_factory\ninsecure = True\ncache = swift.cache\ndelay_auth_decision = True\ntoken_cache_time = 300\nauth_url =http://${KEYSTONE_URL}\ninclude_service_catalog = False\nwww_authenticate_uri = http://${KEYSTONE_URI}\nmemcached_servers = ${IPADDR}:6019\npassword = ${SWIFT_PASSWORD}\nrevocation_cache_time = 60\nmemcache_security_strategy = ENCRYPT\nproject_domain_id = default\n\n[filter:keystoneauth]\nuse = egg:swift#keystoneauth\noperator_roles = admin,swiftoperator,_member_\n" /etc/oio/sds/OPENIO/oioswift-0/proxy-server.conf
    sed -i -e '/filter:tempauth/,+2d' /etc/oio/sds/OPENIO/oioswift-0/proxy-server.conf
    sed -i -e 's@^pipeline =.*@pipeline = catch_errors gatekeeper healthcheck proxy-logging cache bulk tempurl proxy-logging authtoken swift3 s3token keystoneauth proxy-logging copy container-quotas account-quotas slo dlo versioned_writes proxy-logging proxy-server@' /etc/oio/sds/OPENIO/oioswift-0/proxy-server.conf
  fi
}

### Main

prepare

# Firstboot script to setup OpenIO configuration
if [ ! -f /etc/oio/sds/firstboot ]; then
  echo "# Firstboot: Setting up the OpenIO cluster"
  if [ ! -z "${OPENIO_IPADDR}" ]; then
    IPADDR=${OPENIO_IPADDR}
  elif [ ! -z "${OPENIO_IFDEV}" ]; then
    IPADDR=$(ip -4 addr show ${OPENIO_IFDEV} | awk '/inet/ {print $2}' | sed 's#/.*##')
    if [ -z "${IPADDR}" ]; then
      echo "Error: Failed to get IP for device ${OPENIO_IFDEV}"
    fi
  else
    IPADDR=$(ip -4 addr show | grep -v 127.0.0.1 | awk '/inet/ {print $2}' | sed 's#/.*##')
  fi

  # Update Swift credentials
  update_swift_credentials
  set_region
  set_workers
  keystone_config

  # Add supplementaries meta2
  add_meta2

  # Update listenning address
  if [ ! -z "${IPADDR}" ]; then
    echo "> Using ${IPADDR} IP address for services"
    /usr/bin/find /etc/oio /etc/gridinit.d /root /usr/bin/openio-basic-checks -type f -print0 | xargs --no-run-if-empty -0 sed -i "s/127.0.0.1/${IPADDR}/g"
  fi

  # Deploy OpenIO
  initcluster

  # Unlock services
  set_unlock

  # Firstboot is done
  touch /etc/oio/sds/firstboot
fi

# Re-enabling the swift gateway, now that it's ready
sed -i -e 's/^enabled=.*$/enabled=true/' /etc/gridinit.d/OPENIO-oioswift-0.conf

# Activate logs
/usr/sbin/rsyslogd

echo "
     .oo.   .ooo.       OIO Conscience:   ${IPADDR}:6000
  .ooooo.   o ..oo.     OIO Proxy:        ${IPADDR}:6006
 .oooo.     .oo. .o.
.oooo.        .o+ .o.   S3 Endpoint:      http://${IPADDR}:6007
iooo.          .o..oo   S3 Region:        ${REGION}
oooo           .o, :o   S3 SSL:           False
oooi           .o: .o   S3 Signature:     s3v4
iooo.          .o..oo   S3 Access bucket: path-style
.oooo.        .oo .o.   S3 Access key:    ${AKEY}
 .oooo.     .oo. .o.    S3 Secret key:    ${SKEY}
  .ooooo.   o...oo.
    .ooo.   .ioo..      Visit https://docs.openio.io/latest/source/integrations for more informations.
"

# start gridinit
gridinit_start
