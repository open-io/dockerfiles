FROM debian:jessie
MAINTAINER "Vincent Legoll" <vincent.legoll@openio.io>

ENV OIOSDS_RELEASE 17.04
ENV OPENSTACK_RELEASE pike
ENV REPO_OPENIO http://mirror.openio.io/pub/repo/openio/sds/${OIOSDS_RELEASE}/debian
ENV PUPPET_PROFILE docker
ENV PUPPETOPTS --color=none

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget software-properties-common

# Install and configure OpenIO
RUN curl "http://mirror.openio.io/pub/repo/openio/APT-GPG-KEY-OPENIO-0" | apt-key add - \
  && echo "deb ${REPO_OPENIO} jessie/" > /etc/apt/sources.list.d/openio-sds.list

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y puppet-module-openio-openiosds

# Get the "docker" puppet profile for openio-sds
RUN mkdir -p /usr/share/puppet/modules/openiosds \
  && wget https://github.com/vincent-legoll/puppet-openiosds-profile/archive/master.tar.gz \
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
RUN DEBIAN_FRONTEND=noninteractive /usr/share/puppet/modules/openiosds/profiles/install.sh ${PUPPET_PROFILE}
RUN DEBIAN_FRONTEND=noninteractive apt-get clean

VOLUME ["/var/lib/oio/sds/OPENIO"]
ADD openio-docker-init.sh /
EXPOSE 6007
CMD ["/openio-docker-init.sh"]
