# Build docker image

    docker build -t openio/debbuild .

# Build & upload resulting packages

You can upload using http to an oiorepo flask web application:

```console
OIO_REPO_IP=`ip -4 address show dev docker0 | awk '/inet / {print substr($2,0,index($2,"/") - 1)}'`
docker run \
    -e UPLOAD_RESULT="http://${OIO_REPO_IP}:5000/package" \
    -e OIO_PROD="sds" \
    -e OIO_PROD_VER="17.10" \
    -e OIO_DISTRO="debian" \
    -e OIO_DISTRO_VER="jessie" \
    -e OIO_COMPANY="openio" \
    -e OIO_PACKAGE="openio-sds" \
    -v "/local/lib/pbuilder:/var/cache/pbuilder" \
    --privileged="true" \
    --rm \
    openio/debbuild
```
