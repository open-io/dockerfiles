FROM centos:7
MAINTAINER Cedric DELGEHIER <cedric.delgehier@openio.io>

ENV container docker

# https://hub.docker.com/_/centos/
RUN \
    (cd /lib/systemd/system/sysinit.target.wants/ || exit; for i in *; do [ "$i" = systemd-tmpfiles-setup.service ] || rm -f "$i"; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*; \
    yum -y upgrade; \
    yum -y install epel-release; \
    yum -y install sudo rsyslog openssh-server iproute; \
    yum clean all; \
    : Can't log kernel messages unless we're privileged; \
    sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf; \
    sed -i -e 's/^\(Defaults\s*requiretty\)/#--- \1/'  /etc/sudoers; \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

RUN sed -i -e 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config


EXPOSE 22

RUN ssh-keygen -q -t dsa -f /etc/ssh/ssh_host_dsa_key -N ''
RUN ssh-keygen -q -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

RUN echo root:root | chpasswd
RUN install -d -o root -g root -m 700 /root/.ssh
RUN touch /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys


RUN useradd centos -G wheel -s /bin/bash -m
RUN echo centos:centos | chpasswd
RUN install -d -o centos -g centos -m 700 /home/centos/.ssh
RUN touch /home/centos/.ssh/authorized_keys && chmod 600 /home/centos/.ssh/authorized_keys && chown centos: /home/centos/.ssh/authorized_keys

VOLUME ["/sys/fs/cgroup"]

CMD ["/usr/sbin/init"]
