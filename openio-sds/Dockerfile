FROM centos:7
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>

ENV OIOSDS_RELEASE 16.10
ENV REPO_OPENIO http://mirror.openio.io/pub/repo/openio/sds/${OIOSDS_RELEASE}/el/openio-sds-release-${OIOSDS_RELEASE}-1.el.noarch.rpm
ENV PUPPET_PROFILE docker
#ENV ADDITIONAL_PKGS

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
  && yum -y --disableplugin=fastestmirror install ${REPO_OPENIO} \
  && yum -y --disableplugin=fastestmirror update \
  && yum -y --disableplugin=fastestmirror install puppet-openio-sds-profile ${ADDITIONAL_PKGS}
RUN /usr/share/puppet/modules/openiosds/profiles/install.sh ${PUPPET_PROFILE} \
  && yum clean all
VOLUME ["/var/lib/oio"]
ADD openio-docker-init.sh /
CMD ["sh","-c","/openio-docker-init.sh"]
