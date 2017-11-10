FROM ubuntu:xenial
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>

ENV OIOSDS_RELEASE 17.04
ENV OPENSTACK_RELEASE ocata
ENV REPO_OPENIO http://mirror.openio.io/pub/repo/openio/sds/${OIOSDS_RELEASE}/ubuntu
ENV PUPPET_PROFILE docker
ENV PUPPETOPTS --color=none

# Shut up "debconf: unable to initialize frontend: Readline"
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update \
  && apt-get install -y curl wget software-properties-common

# Openstack release
RUN add-apt-repository -y cloud-archive:${OPENSTACK_RELEASE}

# Install and configure OpenIO
RUN curl "http://mirror.openio.io/pub/repo/openio/APT-GPG-KEY-OPENIO-0" | apt-key add - \
  && echo "deb ${REPO_OPENIO} xenial/" > /etc/apt/sources.list.d/openio-sds.list
RUN apt-get update \
  && apt-get install -y puppet-module-openio-openiosds

# Get the "docker" puppet profile for openio-sds
RUN mkdir -p /usr/share/puppet/modules/openiosds \
  && wget https://github.com/open-io/puppet-openiosds-profile/archive/master.tar.gz \
  && tar -C /usr/share/puppet/modules/openiosds -xf /master.tar.gz \
  && mv /usr/share/puppet/modules/openiosds/puppet-openiosds-profile-master /usr/share/puppet/modules/openiosds/profiles \
  && rm /master.tar.gz

# Fix missing /run/gridinit
# Some utilities are not located at the same place as other distros
RUN mkdir -p /run/gridinit \
  && ln -s /bin/sed /usr/bin/sed \
  && ln -s /usr/bin/basename /bin/basename \
  && ln -s /bin/rm /usr/bin/rm

# Install OpenIO SDS
RUN /usr/share/puppet/modules/openiosds/profiles/install.sh ${PUPPET_PROFILE} \
  && apt-get clean

VOLUME ["/var/lib/oio/sds/OPENIO"]
ADD openio-docker-init.sh /
EXPOSE 6007
ADD swift.pp /root/swift.pp
CMD ["/openio-docker-init.sh"]
