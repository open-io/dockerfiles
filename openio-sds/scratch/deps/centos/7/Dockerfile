FROM centos:7
MAINTAINER "Jean-Francois Smigielski" <jf.smigielski@gmail.com>

RUN yum clean all \
  && yum -y --disableplugin=fastestmirror install epel-release \
  && yum -y --disableplugin=fastestmirror install http://mirror.openio.io/pub/repo/openio/sds/17.04/el/openio-sds-release-17.04-1.el.noarch.rpm \
  && rm -rf /var/cache/yum \
  && yum clean all \
  && yum -y --disableplugin=fastestmirror update \
  && yum -y --disableplugin=fastestmirror install puppet-openio-sds-profile \
  && yum -y --disableplugin=fastestmirror install \
    screen cmake make flex bison lcov git gcc gcc-c++ \
    glib2 glib2-devel \
    zeromq3 zeromq3-devel \
    curl libcurl libcurl-devel \
    sqlite sqlite-devel \
    attr libattr libattr-devel \
    apr apr-devel apr-util apr-util-devel httpd httpd-devel mod_wsgi \
    libevent libevent-devel \
    json-c json-c-devel \
    leveldb leveldb-devel \
    lzo lzo-devel \
    python-devel \
    python-virtualenv python-pip \
    liberasurecode liberasurecode-devel \
    zookeeper zookeeper-lib zookeeper-lib-devel \
    beanstalkd redis hiredis hiredis-devel \
    openio-gridinit openio-asn1c \
  && rm -rf /var/cache/yum \
  && yum clean all \
  && pip install --upgrade pip tox virtualenv zkpython \
  && useradd -U -m -G users,wheel openio

CMD ["/usr/bin/env", "bash"]

