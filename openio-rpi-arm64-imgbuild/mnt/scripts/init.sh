#!/bin/bash

set -x
set -e

mv /root/scripts/gridinit.service /lib/systemd/system/gridinit.service
systemctl daemon-reload


mkdir -p /etc/.gridinit_backup/
mv /etc/gridinit.d/* /etc/.gridinit_backup/
systemctl start gridinit

# WAIT=0
# until gridinit_cmd stop || [ $WAIT -eq 20 ]; do
#     WAIT=$((WAIT+1))
#     sleep 1
# done

WAIT=0
until [ -n "$ipaddr" ] || [ $WAIT -eq 20 ]; do
    WAIT=$((WAIT+1))
    sleep 1
    export ipaddr="$(ifconfig eth0 | grep "inet " | awk -F'[: ]+' '{ print $4 }')"
done

envsubst < /root/scripts/openio.pp > /root/scripts/openio_static.pp
puppet apply --no-stringify_facts /root/scripts/openio_static.pp

systemctl stop apache2 memcached redis beanstalkd puppet || true
systemctl disable apache2 memcached redis beanstalkd puppet || true
openio --oio-ns=OPENIO cluster unlockall
openio cluster wait --oio-ns OPENIO -s 10 -d 60
openio --oio-ns=OPENIO directory bootstrap --no-rdir
gridinit_cmd restart @meta0 @meta1
openio --oio-ns=OPENIO cluster unlockall
openio cluster wait --oio-ns OPENIO -s 10 -d 60
openio --oio-ns=OPENIO volume admin bootstrap
openio --oio-ns OPENIO cluster list

# BOOTSTRAP

cat << EOF > /etc/rc.local
#!/bin/sh -e
openio cluster unlockall --oio-ns OPENIO
EOF
