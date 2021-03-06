#!/bin/bash

set -eux -o pipefail

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

test -n "${DOCKER_TEST_CONTAINER_NAME}" || {
    echo "Error: variable DOCKER_TEST_CONTAINER_NAME not set. Exiting."
    exit 1
}
test -n "${DOCKER_IMAGE_NAME}" || {
    echo "Error: variable DOCKER_IMAGE_NAME not set. Exiting."
    exit 1
}

clean_sut() {
    docker kill "${1}"
    docker rm -f "${1}"
    docker system prune -f --volumes
}

# Launch an openio-sds container to test
clean_sut "${DOCKER_TEST_CONTAINER_NAME}" || true # Never fail cleanup
docker run -d --name "${DOCKER_TEST_CONTAINER_NAME}" "${DOCKER_IMAGE_NAME}"

# Build the tester image
TESTER_IMAGE_NAME=openio-sds-tester
docker build -t "${TESTER_IMAGE_NAME}" "${CURRENT_DIR}"/../tester/

# Run tests
docker run --rm -t \
    --network="container:${DOCKER_TEST_CONTAINER_NAME}" \
    -e "SUT_ID=${DOCKER_TEST_CONTAINER_NAME}" \
    -e SUT_IP="$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${DOCKER_TEST_CONTAINER_NAME}")" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    "${TESTER_IMAGE_NAME}" \
|| {
    echo "== Tests failure: please check SUT logs below:"
    docker logs "${DOCKER_TEST_CONTAINER_NAME}"
    echo "=============================================="
    clean_sut "${DOCKER_TEST_CONTAINER_NAME}" || true # Never fail cleanup
    exit 1
}
clean_sut "${DOCKER_TEST_CONTAINER_NAME}" || true # Never fail cleanup
