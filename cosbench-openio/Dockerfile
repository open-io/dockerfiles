FROM ubuntu:16.04

ENV COSVERSION=15e5395

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y \
         dpkg apt-transport-https curl apt-utils netcat net-tools openjdk-8-jre

COPY cosbench-15e5395.tar.gz /root/

RUN tar xf /root/cosbench-${COSVERSION}.tar.gz -C /root/ \
    && rm -f /root/cosbench-${COSVERSION}.tar.gz \
    && mv /root/cosbench-${COSVERSION} /root/cosbench

ADD start-cosbench.sh /root/cosbench/

CMD ["/root/cosbench/start-cosbench.sh"]
