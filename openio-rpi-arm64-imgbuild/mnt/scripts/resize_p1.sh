#!/bin/bash

echo -e "d\n2\nn\np\n\n\n\nw\n" | fdisk /dev/mmcblk0
touch /forcefsck
cat << EOF > /etc/rc.local
#!/bin/sh -e
bash /root/scripts/resize_p2.sh
EOF
reboot
