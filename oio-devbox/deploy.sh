#!/bin/bash

set -eux -o pipefail

test -n "${DOCKER_IMAGE_NAME}" || {
    echo "Error: variable DOCKER_IMAGE_NAME not set. Exiting."
    exit 1
}

DEPLOY_IMAGE_NAME="openio/devbox"
DEPLOY_IMAGE_TAG="latest"

docker tag "${DOCKER_IMAGE_NAME}" "${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}"
docker push "${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}"
