#! /bin/bash -xe

cd "deb-packaging"
git pull origin master
cd "${OIO_DISTRO}-${OIO_DISTRO_VER}/${OIO_PACKAGE}"
bash ../../oio-debbuild.sh "${UPLOAD_RESULT}"
