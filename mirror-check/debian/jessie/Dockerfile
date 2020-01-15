FROM debian:jessie
MAINTAINER "Vincent Legoll <vincent.legoll@openio.io>"

RUN DEBIAN_FRONTEND=noninteractive apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
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

ADD generic/mirror_test.yml /
ADD generic/entrypoint.sh /
ADD generic/ansible.cfg /
ADD generic/inventory /
ADD generic/vars /

ENV ANSIBLE_CONFIG /ansible.cfg

RUN chmod 0755 /entrypoint.sh
RUN DEBIAN_FRONTEND=noninteractive apt-get clean all

ENTRYPOINT ["/entrypoint.sh"]
