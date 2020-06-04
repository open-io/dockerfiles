#!/bin/bash

LATEST=true
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd -P)"

set -eux -o pipefail

test -n "${DOCKER_IMAGE_NAME}" || {
    echo "Error: variable DOCKER_IMAGE_NAME not set. Exiting."
    exit 1
}

DEPLOY_IMAGE_NAME="openio/sds"
DEPLOY_IMAGE_TAG="20.04"

docker tag "${DOCKER_IMAGE_NAME}" "${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}"
docker push "${DEPLOY_IMAGE_NAME}:${DEPLOY_IMAGE_TAG}"

if [ "${LATEST}" == "true" ]
then
    docker tag "${DOCKER_IMAGE_NAME}" "${DEPLOY_IMAGE_NAME}:latest"
    docker push "${DEPLOY_IMAGE_NAME}:latest"

    test -n "${DOCKER_HUB_USR}" || {
        echo "Error: variable DOCKER_HUB_USR not set. Exiting."
        exit 1
    }

    test -n "${DOCKER_HUB_PSW}" || {
        echo "Error: variable DOCKER_HUB_PSW not set. Exiting."
        exit 1
    }

    ## Update README
    README_FILEPATH="${CURRENT_DIR}/DOCKERHUB_DESC.md"

    echo "Acquiring token"
    LOGIN_PAYLOAD="$(jq -n --arg username "$DOCKER_HUB_USR" --arg password "$DOCKER_HUB_PSW" '{username: $username, password: $password}')"
    TOKEN="$(curl -s -H "Content-Type: application/json" -X POST -d "${LOGIN_PAYLOAD}" https://hub.docker.com/v2/users/login/ | jq -r .token)"

    # Send a PATCH request to update the description of the repository
    echo "Sending PATCH request"
    REPO_URL="https://hub.docker.com/v2/repositories/openio/sds/"
    RESPONSE_CODE="$(curl -s --write-out '%{response_code}' --output /dev/null -H "Authorization: JWT ${TOKEN}" -X PATCH --data-urlencode full_description@"${README_FILEPATH}" "${REPO_URL}")"
    echo "Received response code: $RESPONSE_CODE"

    if [ "${RESPONSE_CODE}" -eq 200 ]; then
        exit 0
    else
        exit 1
    fi



fi

