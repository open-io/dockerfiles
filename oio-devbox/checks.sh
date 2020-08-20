#!/bin/bash

set -eu -o pipefail

for CLI in ansible ansible-vault awk bash curl docker git grep make molecule openstack packer python3 sed terraform virtualenv
do
  command -v "${CLI}" >/dev/null || { >&2 echo "Command line '${CLI}' not found" && exit 1;}
done

for DIR in /tmp/mitogen-0.2.9 /venv
do
  test -d "${DIR}" || { >&2 echo "Directory '${DIR}' not found" && exit 1;}
done

for FILE in /venv/dev.pip "${VENV_PATH}"/bin/activate
do
  test -f "${FILE}" || { >&2 echo "File '${FILE}' not found" && exit 1;}
done

echo "== Image is conform. End of Internal Test."
