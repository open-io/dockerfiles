FROM centos:7.3.1611
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>

ENV OIOSDS_RELEASE 16.10
ENV REPO_OPENIO http://mirror.openio.io/pub/repo/openio/sds/${OIOSDS_RELEASE}/el/openio-sds-release-${OIOSDS_RELEASE}-1.el.noarch.rpm
ENV PUPPET_PROFILE docker
ENV PUPPETOPTS --color=none

# Force the mirror definitions to point to the 7.3.1611 subdirectory, as for
# CentOS-Base the default is still to use $releasever (which is just "7")
# and for OpenStack, the default is hardcoded to just "7".
# Then install and configure OpenIO
RUN sed -i -e 's/\$releasever/7.3.1611/g' -e 's/^mirrorlist/#mirrorlist/g' -e 's/^#baseurl=/baseurl=/g' /etc/yum.repos.d/CentOS-Base.repo \
  && yum clean all \
  && yum -y install centos-release-openstack-mitaka \
  && sed -i -e 's|centos/7/cloud|centos/7.3.1611/cloud|g' /etc/yum.repos.d/CentOS-OpenStack-mitaka.repo \
  && yum -y --disableplugin=fastestmirror install ${REPO_OPENIO} \
  && yum -y --disableplugin=fastestmirror update \
  && yum -y --disableplugin=fastestmirror install puppet-openio-sds-profile ${ADDITIONAL_PKGS} \
  && /usr/share/puppet/modules/openiosds/profiles/install.sh ${PUPPET_PROFILE} \
  && rm -rf /var/cache/yum \
  && yum clean all
VOLUME ["/var/lib/oio"]
ADD openio-docker-init.sh /
EXPOSE 6007
CMD ["/openio-docker-init.sh"]
