FROM ubuntu:16.04

ENV COSVERSION=674fa86
ENV COSPKGNAME="cosbench-"
ENV COSNAME="cosbench-"
ENV COSFILENAMEEXT=".tgz"

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
         dpkg apt-transport-https curl apt-utils netcat net-tools openjdk-8-jre

COPY ${COSPKGNAME}${COSVERSION}${COSFILENAMEEXT} /

RUN tar xf /${COSPKGNAME}${COSVERSION}${COSFILENAMEEXT} -C / \
    && mv /${COSNAME}${COSVERSION} /cosbench \
    && rm -f /${COSPKGNAME}${COSVERSION}${COSFILENAMEEXT} \
    && rm -rf /${COSNAME}${COSVERSION} \
    && rm -f /bin/sh && ln -s /bin/bash /bin/sh

ADD start-cosbench.sh /cosbench/

CMD ["/cosbench/start-cosbench.sh"]
