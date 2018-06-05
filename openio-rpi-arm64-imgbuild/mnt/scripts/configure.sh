#!/bin/bash

set -e

export PATH="$PATH:/usr/sbin:/sbin:/bin"

export ipaddr="127.0.0.1"
cat << EOF > /root/scripts/openio_static.pp
class {'gridinit':
  no_exec => true,
}

EOF

envsubst < /root/scripts/openio.pp >> /root/scripts/openio_static.pp

export FACTER_system_uptime={"seconds"=>0, "hours"=>0, "days"=>0, "uptime"=>"0 days"}
export FACTER_ipaddress="127.0.0.1"
export FACTER_memorysize_mb=900
export FACTER_memoryfree_mb=400
export FACTER_swapsize_mb="0.00"
export FACTER_swapfree_mb="0.00"

puppet apply --no-stringify_facts /root/scripts/openio_static.pp
mv /lib/systemd/system/gridinit.service /root/scripts/gridinit.service
cat << EOF > /etc/rc.local
#!/bin/sh -e
bash /root/scripts/resize_p1.sh
EOF
