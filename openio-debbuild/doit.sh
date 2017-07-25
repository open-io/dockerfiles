#! /bin/bash -xe

cd "deb-packaging"
git pull origin master
cd "${OIO_DISTRO}-${OIO_DISTRO_VER}/${OIO_PACKAGE}"
DISTID=${OIO_DISTRO} ARCH=${OIO_ARCH} bash ../../oio-debbuild.sh "${UPLOAD_RESULT}"
