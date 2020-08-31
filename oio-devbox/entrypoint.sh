#!/bin/bash

set -eu -o pipefail

##### Determine User and Groups at runtime
USER_UID=${USER_UID:-1000}
USER_GID=${USER_GID:-1000}
USER_NAME="${USER_NAME:-openio}"
USER_HOME="${USER_HOME:-/home/${USER_NAME}}"
USER_GROUPNAME="${USER_GROUPNAME:-${USER_NAME}}"
### User: we want UID to be the same as on the host, to avoid writing files as root on the shared folders
# Create default group for the user (same name, same ID by default)
addgroup -g "${USER_GID}" "${USER_GROUPNAME}"
# Create user and its home directory
adduser -h "${USER_HOME}" -u "${USER_UID}" -G "${USER_GROUPNAME}" -s /bin/bash -D "${USER_NAME}"
echo "${USER_NAME}:${USER_NAME}" | chpasswd >/dev/null 2>&1
# Ensure that Ansible directory is created with the correct rights
mkdir -p "${USER_HOME}/.ansible"
chown -R "${USER_UID}:${USER_GID}" "${USER_HOME}/.ansible"

# Docker Group: we also want the default user to be part of the group owning /var/run/docker.sock
DOCKER_SOCKET=/var/run/docker.sock
if test -f "${DOCKER_SOCKET}"
then
  chmod g+w "${DOCKER_SOCKET}" # Ensure that the group owning the socket can write to it
  DOCKER_GROUP="$(stat -c %G "${DOCKER_SOCKET}")"
  DOCKER_GROUP_GID="$(stat -c %g "${DOCKER_SOCKET}")"
  grep -q "${DOCKER_GROUP}" /etc/passwd || addgroup -g "${DOCKER_GROUP_GID}" "${DOCKER_GROUP}"
  addgroup "${USER_NAME}" "${DOCKER_GROUP}"
fi

####### Determine the command to run
CMD_TO_RUN=("$@")

if [ "${1}" == "--" ]
then
  # Interactive session
  CMD_TO_RUN=("bash")
  echo "== 1st argument is '--': Entering Interactive session"
fi

exec sudo --preserve-env --user="${USER_NAME}" --set-home bash -c "cd ${PWD} && . ${VENV_PATH}/bin/activate && ${CMD_TO_RUN[*]}"
