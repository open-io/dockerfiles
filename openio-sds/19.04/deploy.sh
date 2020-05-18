#!/bin/bash

LATEST="${LATEST:-false}"

set -eux -o pipefail

test -n "${DOCKER_IMAGE_NAME}" || {
    echo "Error: variable DOCKER_IMAGE_NAME not set. Exiting."
    exit 1
}

DEPLOY_IMAGE_NAME="openio/sds"
DEPLOY_IMAGE_TAG="19.04"

docker tag "${DOCKER_IMAGE_NAME}" "${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}"
docker push "${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}"

if [ "${LATEST}" == "true" ]
then
    docker tag "${DOCKER_IMAGE_NAME}" "${DEPLOY_IMAGE_NAME}:latest"
    docker push "${DEPLOY_IMAGE_NAME}:latest"
fi
