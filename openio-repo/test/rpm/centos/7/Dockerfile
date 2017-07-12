FROM centos:7

# For passing docker-build-time params
ARG DOCKER_HOST_IP

RUN yum install -y epel-release

# Add new OpenIO SDS repository
ADD oio-sds.repo /etc/yum.repos.d

# Make the docker host's IP address known inside the container
RUN sed -i -e "s/DOCKER_HOST_IP/${DOCKER_HOST_IP}/" /etc/yum.repos.d/oio-sds.repo

# Trust repository public key
ADD keyFile.pub /
RUN rpm --import /keyFile.pub
RUN rm -f /keyFile.pub

# Run bash to allow manual testing of repository
CMD ["yum", "install", "-y", "openio-sds-tools"]
