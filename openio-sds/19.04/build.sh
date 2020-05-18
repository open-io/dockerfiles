#!/bin/bash
set -eux -o pipefail

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
OIOSDS_RELEASE="$(basename "${CURRENT_DIR}")"

exec bash "${CURRENT_DIR}/../sds-build.sh" "${OIOSDS_RELEASE}"
