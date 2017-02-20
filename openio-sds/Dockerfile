FROM centos:7
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>

ENV OIOSDS_RELEASE 16.10
ENV REPO_OPENIO http://mirror.openio.io/pub/repo/openio/sds/${OIOSDS_RELEASE}/el/openio-sds-release-${OIOSDS_RELEASE}-1.el.noarch.rpm
#ENV ADDITIONAL_PKGS
ENV PUPPET_PROFILE docker

# Install and configure OpenIO
RUN yum clean all \
  && yum -y --disableplugin=fastestmirror install ${REPO_OPENIO} \
  && yum -y --disableplugin=fastestmirror update \
  && yum -y --disableplugin=fastestmirror install puppet-openio-sds-profile ${ADDITIONAL_PKGS} \
  && /usr/share/puppet/modules/openiosds/profiles/install.sh ${PUPPET_PROFILE} \
  && yum clean all
VOLUME ["/var/lib/oio"]
ADD openio-docker-init.sh /
EXPOSE 6007
CMD ["sh","-c","/openio-docker-init.sh"]
