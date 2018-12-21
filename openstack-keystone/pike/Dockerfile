FROM centos:7
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>

ENV OS_RELEASE=pike

RUN yum clean all \
  && yum -y update \
  && yum -y install centos-release-openstack-${OS_RELEASE} \
  && yum -y install openstack-keystone openstack-utils python-openstackclient nmap-ncat \
  && yum clean all

ADD keystone-v3.sh /
EXPOSE 5000 35357

CMD ["/keystone-v3.sh"]
