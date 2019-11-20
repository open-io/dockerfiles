FROM centos:7
MAINTAINER "Vincent Legoll <vincent.legoll@openio.io>"

RUN yum update -y
RUN yum install -y git ansible

RUN git clone https://github.com/open-io/ansible-role-openio-repository.git

ADD generic/mirror_test.yml /
ADD generic/ansible.cfg /
ADD generic/inventory /
ADD generic/vars /

ENV ANSIBLE_CONFIG /ansible.cfg

RUN yum clean all

ENTRYPOINT ["ansible-playbook", "mirror_test.yml"]
