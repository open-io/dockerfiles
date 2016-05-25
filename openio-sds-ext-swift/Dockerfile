FROM centos:7
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>

ENV REPO_OPENIO http://mirror.openio.io/pub/repo/openio/sds/16.04/el/openio-sds-release-16.04-1.el.noarch.rpm
ENV REPO_OPENSTACK https://repos.fedorapeople.org/repos/openstack/openstack-mitaka/rdo-release-mitaka-3.noarch.rpm
ENV ADDITIONAL_PKGS puppet memcached python-swiftclient
#ENV PUPPET_PROFILE docker-ext-swift
ENV PUPPET_PROFILE docker

# Enable systemd
ENV container docker
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
  rm -f /lib/systemd/system/multi-user.target.wants/*;\
  rm -f /etc/systemd/system/*.wants/*;\
  rm -f /lib/systemd/system/local-fs.target.wants/*; \
  rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
  rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
  rm -f /lib/systemd/system/basic.target.wants/*;\
  rm -f /lib/systemd/system/anaconda.target.wants/*;
VOLUME [ "/sys/fs/cgroup" ]

# Install and configure OpenIO
RUN yum clean all \
  && yum -y --disableplugin=fastestmirror install \
      ${REPO_OPENIO} \
      ${REPO_OPENSTACK} \
  && yum -y --disableplugin=fastestmirror update \
  && yum -y --disableplugin=fastestmirror install \
       python-swiftclient.noarch \
       python-openstackclient \
       openio-sds-logrotate \
       openio-sds-rsyslog \
       openio-gridinit \
       openio-sds-swift \
       openstack-swift-proxy \
       puppet-openio-sds-profile-docker \
       python-pip \
       ${ADDITIONAL_PKGS}
ADD docker-ext-swift-keystone.pp /
RUN /usr/bin/puppet module install openstack-keystone && \
  /usr/bin/puppet apply --no-stringify_facts --show_diff /docker-ext-swift-keystone.pp && \
  pip install awscli && \
  yum clean all
ADD openio-docker-init-swift.sh /
ADD docker-ext-swift.pp /
VOLUME ["/var/lib/oio"]
CMD ["sh","-c","/openio-docker-init-swift.sh"]
