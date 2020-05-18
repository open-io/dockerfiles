# openio/sds

Build Docker image based on [ansible playbook](https://github.com/open-io/ansible-playbook-openio-deployment)

## How to get this image from the hub

To get the latest built of this version on the [docker hub](https://hub.docker.com/r/openio/sds)

```shell
docker pull openio/sds:19.10
```

## How to (re-)build this image

First set up the environement:

```shell
# Configure build
export SDS_VERSION=19.10
export DOCKER_IMAGE_NAME="openio-sds-${SDS_VERSION}"
export DOCKER_BUILD_CONTAINER_NAME="openio-sds-${SDS_VERSION}-build"
export DOCKER_TEST_CONTAINER_NAME="openio-sds-${SDS_VERSION}-test"

# Get the source
git clone https://github.com/open-io/dockerfiles.git
cd "./dockerfiles/openio-sds/${SDS_VERSION}/"

# Generate the builder image, which holds all the required tooling in the correct versions
docker build -t "openio-sds-docker-builder:${SDS_VERSION}" ./jenkins/
```

Then, execute the build step, using this "builder" image (which uses Docker-on-Docker pattern):

```shell
docker run --rm -t -v /var/run/docker.sock:/var/run/docker.sock -u root -v "$(pwd):$(pwd)" -w "$(pwd)" \
    -e DOCKER_BUILD_CONTAINER_NAME -e DOCKER_IMAGE_NAME -e DOCKER_TEST_CONTAINER_NAME  "openio-sds-docker-builder:${SDS_VERSION}" \
        bash ./build.sh
```

Now, execute the test harness on this newly built image:

```shell
docker run --rm -t -v /var/run/docker.sock:/var/run/docker.sock -u root -v "$(pwd):$(pwd)" -w "$(pwd)" \
    -e DOCKER_BUILD_CONTAINER_NAME -e DOCKER_IMAGE_NAME -e DOCKER_TEST_CONTAINER_NAME  "openio-sds-docker-builder:${SDS_VERSION}" \
        bash ./test.sh
```

Finally, if you want to tag and deploy the image, execute the `deploy.sh` script:

```shell
export LATEST=true # Only if you want the image to be tagged as latest, along with current tag
test -n "${DOCKER_IMAGE_NAME}" # Required to select the image to tag
bash ./deploy.sh
```
