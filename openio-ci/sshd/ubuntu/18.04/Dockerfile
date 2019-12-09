  
FROM ubuntu:18.04
MAINTAINER Cedric DELGEHIER <cedric.delgehier@openio.io>

ENV container docker

# https://hub.docker.com/_/ubuntu/
RUN \
    apt-get update; \
    apt-get install -y systemd; \
    (cd /lib/systemd/system/sysinit.target.wants/ || exit; for i in *; do [ "$i" = systemd-tmpfiles-setup.service ] || rm -f "$i"; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*; \
    systemctl mask dev-mqueue.mount dev-hugepages.mount \
      systemd-remount-fs.service sys-kernel-config.mount \
      sys-kernel-debug.mount sys-fs-fuse-connections.mount \
      systemd-logind.service getty.service getty.target; \
    apt update; \
    apt install -y openssh-server sudo iproute2 systemd rsyslog; \
    : Can't log kernel messages unless we're privileged; \
    sed -i 's/^\(module(load="imklog" permitnonkernelfacility="on"\)/#\1/' /etc/rsyslog.conf; \
    echo '%sudo ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers; \
    sed -ri 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config; \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*; 

RUN mkdir /var/run/sshd
RUN yes y | ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
RUN yes y | ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''

RUN echo root:root | chpasswd
RUN install -d -o root -g root -m 700 /root/.ssh
RUN touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys

RUN useradd ubuntu -G sudo -s /bin/bash -m
RUN echo 'ubuntu:ubuntu' | chpasswd
RUN install -d -o ubuntu -g ubuntu -m 700 /home/ubuntu/.ssh
RUN touch /home/ubuntu/.ssh/authorized_keys && chmod 600 /home/ubuntu/.ssh/authorized_keys && chown ubuntu: /home/ubuntu/.ssh/authorized_keys


VOLUME ["/sys/fs/cgroup"]
CMD ["/sbin/init"]