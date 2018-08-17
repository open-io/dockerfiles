FROM centos:7
MAINTAINER "Vincent Legoll <vincent.legoll@openio.io>"

RUN yum update -y
RUN yum install -y git ansible

RUN git clone https://github.com/open-io/ansible-role-openio-repository.git

ADD mirror_test.yml /
ADD ansible.cfg /
ADD inventory /

ENV ANSIBLE_CONFIG /ansible.cfg

ENTRYPOINT ["ansible-playbook", "mirror_test.yml"]
