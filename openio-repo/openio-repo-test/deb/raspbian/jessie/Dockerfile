FROM raspbian:jessie

RUN apt-get update && apt-get install -y curl

# Test installing a package from the repository
CMD curl "http://${OIO_REPO_IP}:${OIO_REPO_PORT}/pub/repo/openio/APT-GPG-KEY-OPENIO-0" | apt-key add - && \
    echo "deb http://${OIO_REPO_IP}:${OIO_REPO_PORT}/${OIO_REPO_PATH} /" > /etc/apt/sources.list.d/oio-sds.list && \
    apt-get update && \
    apt-get install -y ${OIO_PACKAGE}
