#!/bin/bash

RELEASE=$1
MIRROR=$2

cd /
git clone https://github.com/open-io/ansible-role-openio-repository.git

cd ansible-role-openio-repository
git checkout "${RELEASE%/*}"
cd /

ansible-playbook mirror_test.yml -e "repo_release=${RELEASE}" -e "openio_repository_mirror_host=${MIRROR}"
