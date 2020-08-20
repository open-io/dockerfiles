#!/bin/bash

set -eux -o pipefail

test -n "${DOCKER_IMAGE_NAME}" || {
  echo "Error: variable DOCKER_IMAGE_NAME not set. Exiting."
  exit 1
}

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

docker build -t "${DOCKER_IMAGE_NAME}" "${CURRENT_DIR}/"
