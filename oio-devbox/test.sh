#!/bin/bash

set -eux -o pipefail

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

test -n "${DOCKER_IMAGE_NAME}" || {
    echo "Error: variable DOCKER_IMAGE_NAME not set. Exiting."
    exit 1
}

docker image ls | grep "${DOCKER_IMAGE_NAME}"

docker run --rm --volume=/var/run/docker.sock:/var/run/docker.sock --volume="${CURRENT_DIR}:/repo" "${DOCKER_IMAGE_NAME}" bash /repo/checks.sh
