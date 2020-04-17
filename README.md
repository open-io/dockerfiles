# OpenIO's Dockerfiles

This repository stores OpenIO's Docker Images.

In order to be built, tested and deployed, each Docker image is expected to follow these conventions:

- An image is represented by a directory. I can be anywhere in the repository
- For a given image, the corresponding directory must provides 3 shell scripts (to allow freedom of the implementation):
  - `build.sh` which builds the image, with a temporary name
  - `test.sh`, which test the freshly built (and temporary) image
  - `deploy.sh`, which deploy the image where it's expected to be deployed
- The shell scripts expect the following environment variables to be defined (and exported). The CI (Jenkins) takes care of this for you, but it is required to be done manually
  when building imags locally:
  - `DOCKER_IMAGE_NAME`: the temporary name of the image to be built and tested
  - `DOCKER_BUILD_CONTAINER_NAME`: the temporary name of any "build" container used during the build
  - `DOCKER_TEST_CONTAINER_NAME`: the temporary name of any "test" container used for testing the temporary image
- For a given image, the CI steps (build, test and deploy) are run inside a custom Docker container, defined in the file `./jenkins/Dockerfile` on each image repository.
  This is where you define any dependency used by your scripts (for instance if `test.sh` execute `bats` tests, then `./jenkins/Dockerfile` must install `bats` CLI).
- The script `deploy.sh` is responsible to set the final name of the Docker image, including its tag
