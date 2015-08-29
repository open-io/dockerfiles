FROM centos:7
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>
ENV REPO_EPEL http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm
ENV REPO_OPENIO http://mirror.openio.io/pub/repo/openio/sds/centos/7/common/x86_64/openio-sds-release-0-2.el7.noarch.rpm
ENV REPO_OPENIO_TESTING http://mirror.openio.io/pub/repo/stable/openio/sds/centos/7/common/x86_64/openio-sds-testing-release-0-1.el7.noarch.rpm
ENV PUPPET_PROFILE docker
ENV ADDITIONAL_PKGS python-oiopy
RUN yum -y install ${REPO_EPEL} \
    ${REPO_OPENIO} \
    ${REPO_OPENIO_TESTING} \
  && yum -y update \
  && yum -y install puppet-openio-sds-profile-${PUPPET_PROFILE} ${ADDITIONAL_PKGS} \
  && /usr/share/puppet/modules/openiosds/profiles/install.sh ${PUPPET_PROFILE}
VOLUME ["/var/lib/oio"]
CMD ["sh","-c","/usr/bin/gridinit -d /etc/gridinit.conf && bash"]
