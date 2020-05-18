#!/bin/bash

set -eux -o pipefail

CONTAINER_IP="$(hostname -i)"

command -v curl >/dev/null 2>&1 || {
    echo "ERROR: No curl command found."
    exit 1
}

# Healtcheck on the S3 gateway
curl --fail --silent --show-error --location "${CONTAINER_IP}:6007/healthcheck"
