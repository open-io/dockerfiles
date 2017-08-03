#! /bin/bash -x


echo "Going into repo: ${GIT_REPO_NAME}"
cd "${GIT_REPO_NAME}"

echo "Fetching everything"
git fetch --all

echo "Resetting repo state to branch: ${GIT_BRANCH}"
git reset --hard "remotes/origin/${GIT_BRANCH}"

echo "Going into package directory: ${OIO_DISTRO}-${OIO_DISTRO_VER}/${OIO_PACKAGE}"
cd "${OIO_DISTRO}-${OIO_DISTRO_VER}/${OIO_PACKAGE}"

echo "Updating binfmts, if needed..."

# Ensure we can run arm binaries automagically through qemu via binfmt_misc
update-binfmts --display | grep -q 'qemu-arm (enabled)'
if [ $? -ne 0 ]; then
    sudo update-binfmts --enable qemu-arm
fi

echo "Running build script"
DISTID=${OIO_DISTRO} ARCH=${OIO_ARCH} bash ../../oio-debbuild.sh "${UPLOAD_RESULT}"
