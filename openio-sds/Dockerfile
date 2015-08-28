FROM centos:7
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>
RUN yum -y install http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm http://mirror.openio.io/pub/repo/openio/sds/centos/7/common/x86_64/openio-sds-release-0-2.el7.noarch.rpm http://mirror.openio.io/pub/repo/stable/openio/sds/centos/7/common/x86_64/openio-sds-testing-release-0-1.el7.noarch.rpm && yum -y install puppet-openio-sds-profile-docker.noarch && /usr/share/puppet/modules/openiosds/profiles/install.sh docker
VOLUME ["/var/lib/oio"]
CMD ["sh","-c","/usr/bin/gridinit -d /etc/gridinit.conf && bash"]
