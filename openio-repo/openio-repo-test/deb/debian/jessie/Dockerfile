FROM debian:jessie-backports

RUN apt-get update && apt-get install -y curl

# Test installing a package from the repository
CMD curl "http://${OIO_REPO_IP}:${OIOREPO_PORT}/pub/keyFile.pub" | apt-key add - && \
    echo "deb http://${OIO_REPO_IP}:${OIOREPO_PORT}/${OIOREPO_PATH} /" > /etc/apt/sources.list.d/oio-sds.list && \
    apt-get update && \
    apt-get install -y ${OIO_PACKAGE}
