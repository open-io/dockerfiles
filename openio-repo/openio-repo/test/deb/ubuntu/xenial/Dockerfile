FROM ubuntu:xenial

# For passing docker-build-time params
ARG DOCKER_HOST_IP

# Add new OpenIO SDS repository
ADD oio-sds.list /etc/apt/sources.list.d

# Make the docker host's IP address known inside the container
RUN sed -i -e "s/DOCKER_HOST_IP/${DOCKER_HOST_IP}/" /etc/apt/sources.list.d/oio-sds.list

# Trust repository public key
ADD keyFile.pub /
RUN apt-key add /keyFile.pub
RUN rm -f /keyFile.pub

# Test installing a package from the repository
CMD apt-get update && apt-get install -y openio-sds
