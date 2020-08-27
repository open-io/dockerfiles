#!/bin/bash

set -eu -o pipefail

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

test -n "${DOCKER_IMAGE_NAME}" || {
    echo "Error: variable DOCKER_IMAGE_NAME not set. Exiting."
    exit 1
}

# This shell syntax tries to "split" the docker image name to isolate the tag
# case 1: no tag specified, then both grep will be the same value
# case 2: a tag is specified (e.g. openio/devbox:python2 for instance), then the grep will test different elements: 1st the image name, 2nd the tag
docker image ls | grep "${DOCKER_IMAGE_NAME%:*}" | grep -q "${DOCKER_IMAGE_NAME#*:}"

docker run --rm --volume=/var/run/docker.sock:/var/run/docker.sock --volume="${CURRENT_DIR}:/repo" "${DOCKER_IMAGE_NAME}" bash /repo/checks.sh
