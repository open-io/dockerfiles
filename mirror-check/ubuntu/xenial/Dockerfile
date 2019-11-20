FROM ubuntu:xenial
MAINTAINER "Vincent Legoll <vincent.legoll@openio.io>"

RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y git python-pip build-essential libffi-dev

RUN pip install --upgrade pip

# Get past the outdated 2.0.0.2 version
RUN pip install "ansible>=2.5,<2.6"

RUN git clone https://github.com/open-io/ansible-role-openio-repository.git

ADD generic/mirror_test.yml /
ADD generic/ansible.cfg /
ADD generic/inventory /
ADD generic/vars /

ENV ANSIBLE_CONFIG /ansible.cfg

RUN apt-get clean all

ENTRYPOINT ["ansible-playbook", "mirror_test.yml"]
