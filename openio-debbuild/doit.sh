#! /bin/bash -x

echo "Going into repo: ${GIT_REPO_NAME}"
cd "${GIT_REPO_NAME}"

echo "Removing the 'build' remote, if already there"
git remote | grep -q "^build$" >& /dev/null
if [[ $? -eq 0 ]]; then
    git remote remove "build"
else
    echo "Git remote 'build' not present, nothing to do"
fi

echo "Adding the specified git remote repository"
git remote add "build" "${GIT_REMOTE}"
if [[ $? -ne 0 ]]; then
    echo "Cannot create remote, pointing to git repository ${GIT_REMOTE}"
    exit 1
fi

echo "Fetching the specified branch"
git fetch build "${GIT_BRANCH}"

echo "Resetting repo state to branch: ${GIT_BRANCH}"
git reset --hard "remotes/build/${GIT_BRANCH}"

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
