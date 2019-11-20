FROM ubuntu:bionic
MAINTAINER "Vincent Legoll <vincent.legoll@openio.io>"

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y git ansible python-pip

RUN pip install --upgrade pip

RUN git clone https://github.com/open-io/ansible-role-openio-repository.git

ADD generic/mirror_test.yml /
ADD generic/ansible.cfg /
ADD generic/inventory /
ADD generic/vars /

ENV ANSIBLE_CONFIG /ansible.cfg

RUN apt-get clean all

ENTRYPOINT ["ansible-playbook", "mirror_test.yml"]
