#!/bin/bash

set -eu -o pipefail

for CLI in ansible ansible-vault awk bash curl docker git grep make molecule packer python2 python3 sed terraform virtualenv
do
  command -v "${CLI}" >/dev/null || { >&2 echo "Command line '${CLI}' not found" && exit 1;}
done


test -d /tmp/mitogen-0.2.9

echo "== Image is conform. End of Internal Test."
