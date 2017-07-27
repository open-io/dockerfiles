#! /bin/bash -xe

cd "deb-packaging"
git pull origin master
cd "${OIO_DISTRO}-${OIO_DISTRO_VER}/${OIO_PACKAGE}"

# Ensure we can run arm binaries automagically through qemu via binfmt_misc
update-binfmts --display | grep -q 'qemu-arm (enabled)'
if [ $? -ne 0 ]; then
    sudo update-binfmts --enable qemu-arm
fi

DISTID=${OIO_DISTRO} ARCH=${OIO_ARCH} bash ../../oio-debbuild.sh "${UPLOAD_RESULT}"
