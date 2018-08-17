FROM ubuntu:bionic
MAINTAINER "Vincent Legoll <vincent.legoll@openio.io>"

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y git ansible

RUN git clone https://github.com/open-io/ansible-role-openio-repository.git

ADD mirror_test.yml /
ADD ansible.cfg /
ADD inventory /

ENV ANSIBLE_CONFIG /ansible.cfg

ENTRYPOINT ["ansible-playbook", "mirror_test.yml"]
