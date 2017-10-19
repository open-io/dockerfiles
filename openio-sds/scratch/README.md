# openio/sds from scratch : the Dockerfile

## Build

First build the docker image based on a Centos 7 with all the dependencies of openio-sds:

```console
docker build -t oiosds:scratch-centos7-deps scratch/deps/centos/7
```

Then build one image for each openio-sds github branch you want to:

```console
while read TAG COMMIT ; do
  COMMIT=${COMMIT:-$TAG}
  docker build -t oiosds:scratch-centos7-sds-${TAG} --build-arg COMMIT_ID=${COMMIT} scratch/sds/centos/7
do <<EOF
4.x    origin/4.x
4.1.x  origin/4.1.x
4.1.4
4.1.3
4.1.2
4.1.1
4.1.0
EOF
```

## Run

You can run both images as container, as they offer a bash as main command:

```console
docker run -ti oiosds:scratch-centos7-deps
```

```console
TAG=4.1.x
docker run -ti oiosds:scratch-centos7-sds-${TAG}
```

