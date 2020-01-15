FROM centos:7
MAINTAINER "Vincent Legoll <vincent.legoll@openio.io>"

RUN yum update -y
RUN yum install -y git ansible

ADD generic/mirror_test.yml /
ADD generic/entrypoint.sh /
ADD generic/ansible.cfg /
ADD generic/inventory /
ADD generic/vars /

ENV ANSIBLE_CONFIG /ansible.cfg

RUN chmod 0755 /entrypoint.sh
RUN yum clean all

ENTRYPOINT ["/entrypoint.sh"]
