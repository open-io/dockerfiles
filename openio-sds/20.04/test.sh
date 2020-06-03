#!/bin/bash

set -eu -o pipefail

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

test -n "${DOCKER_IMAGE_NAME}" || {
    echo "Error: variable DOCKER_IMAGE_NAME not set. Exiting."
    exit 1
}

function clean_sut() {
    echo "== 🧽 Cleaning Up..."
    docker-compose down -v --remove-orphans || true
    docker system prune -f --volumes || true
}

for TEST_SUITE_DIR in "${CURRENT_DIR}"/tests/*
do
    TEST_SUITE_NAME="$(basename "${TEST_SUITE_DIR}")"
    echo "== 🔎 Running Test Suite ${TEST_SUITE_NAME}..."

    # Prepare env variables for docker-compose
    COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-oio}-${TEST_SUITE_NAME}"
    export COMPOSE_PROJECT_NAME

    pushd "${TEST_SUITE_DIR}"
    # Cleanup previous running instances
    clean_sut

    # Start SUT
    docker-compose up -d sut

    # Run test harness and report the same exit code as the container "tester"
    docker-compose up --build --exit-code-from=tester tester

    # Cleanup previous running instances
    clean_sut

done

exit 0
