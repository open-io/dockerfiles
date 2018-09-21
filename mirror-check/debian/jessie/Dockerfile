FROM debian:jessie
MAINTAINER "Vincent Legoll <vincent.legoll@openio.io>"

RUN apt-get update
RUN apt-get upgrade -y

RUN apt-get install -y \
    build-essential \
    git \
    libssl-dev \
    libffi-dev \
    python-pip \
    python-dev \
    python-setuptools

RUN pip install -U pip
RUN pip install -U setuptools

# Get past the outdated 2.0.0.2 version
RUN pip install "ansible>=2.5,<2.6"

RUN git clone https://github.com/open-io/ansible-role-openio-repository.git

ADD mirror_test.yml /
ADD ansible.cfg /
ADD inventory /

ENV ANSIBLE_CONFIG /ansible.cfg

RUN apt-get clean all

ENTRYPOINT ["ansible-playbook", "mirror_test.yml"]
