#!/bin/bash

resize2fs /dev/mmcblk0p2
cat << EOF > /etc/rc.local
#!/bin/sh -e
EOF
