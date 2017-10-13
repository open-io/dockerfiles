FROM centos:7

ARG AWS_S3_HOST
ARG AWS_S3_PORT

RUN rm -rf /var/cache/yum
RUN yum -y clean all
RUN yum -y install deltarpm

RUN yum -y update

RUN yum -y install epel-release
RUN yum -y install git python-pip python-virtualenv
RUN yum -y install libevent-devel libxml2-devel libxslt-devel zlib-devel

RUN git clone https://github.com/ceph/s3-tests.git

COPY s3-ceph.cfg /

CMD echo "${AWS_S3_HOST} s3host" >> /etc/hosts && \
    sed -i -e "s/port = 6007/port = ${AWS_S3_PORT}/" /s3-ceph.cfg && \
    cd /s3-tests && \
    git pull origin master && \
    ./bootstrap && \
    S3TEST_CONF=/s3-ceph.cfg ./virtualenv/bin/nosetests -v
