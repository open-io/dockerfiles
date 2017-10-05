FROM ubuntu:xenial
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>

ENV OIOSDS_RELEASE 17.04
ENV REPO_OPENIO http://mirror.openio.io/pub/repo/openio/sds/${OIOSDS_RELEASE}/ubuntu
ENV PUPPET_PROFILE docker
ENV PUPPETOPTS --color=none

RUN apt-get update
RUN apt-get install -y curl wget

# For add-apt-repository
RUN apt-get install -y software-properties-common

# OpenOI 17.04 needs at least ocata's swift (2.13.0) which is not in base repo
RUN add-apt-repository -y cloud-archive:ocata

# Install and configure OpenIO
RUN curl "http://mirror.openio.io/pub/repo/openio/APT-GPG-KEY-OPENIO-0" | apt-key add -
RUN echo "deb ${REPO_OPENIO} xenial/" > /etc/apt/sources.list.d/oio-sds.list
RUN apt clean all
RUN apt-get update
RUN apt-get install -y puppet-module-openio-openiosds

# Get the "docker" puppet profile for openio-sds
RUN mkdir -p /usr/share/puppet/modules/openiosds
RUN wget https://github.com/open-io/puppet-openiosds-profile/archive/master.tar.gz
RUN tar -C /usr/share/puppet/modules/openiosds -xf /master.tar.gz
RUN mv /usr/share/puppet/modules/openiosds/puppet-openiosds-profile-master /usr/share/puppet/modules/openiosds/profiles
RUN rm /master.tar.gz

# This is missing from the puppet profile
RUN mkdir -p /run/gridinit

# Some utilities are not located at the same place as other distros
RUN ln -s /bin/sed /usr/bin/sed
RUN ln -s /usr/bin/basename /bin/basename
RUN ln -s /bin/rm /usr/bin/rm

RUN /usr/share/puppet/modules/openiosds/profiles/install.sh ${PUPPET_PROFILE}

VOLUME ["/var/lib/oio"]
ADD openio-docker-init.sh /
EXPOSE 6007
CMD ["/bin/bash", "/openio-docker-init.sh"]
