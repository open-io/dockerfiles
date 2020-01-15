FROM ubuntu:bionic
MAINTAINER "Vincent Legoll <vincent.legoll@openio.io>"

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y git ansible python-pip

RUN pip install --upgrade pip

ADD generic/mirror_test.yml /
ADD generic/entrypoint.sh /
ADD generic/ansible.cfg /
ADD generic/inventory /
ADD generic/vars /

ENV ANSIBLE_CONFIG /ansible.cfg

RUN chmod 0755 /entrypoint.sh
RUN DEBIAN_FRONTEND=noninteractive apt-get clean all

ENTRYPOINT ["/entrypoint.sh"]
