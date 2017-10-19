FROM alpine:edge
MAINTAINER "Romain Acciari" <romain.acciari@openio.io>

RUN echo http://nl.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories \
    && apk add --no-cache py-sphinx rsync bash python py-beautifulsoup4 py-lxml

VOLUME ["/mnt"]
EXPOSE 3000

CMD cd /mnt \
    && if [ -z "$DISABLE_BUILD" ]; then \
         tools/build-all.sh ; \
       fi \
    && if [ ! -z "$ENABLE_HTTP" ]; then \
         cd result-docs \
         && python -m SimpleHTTPServer 3000 ; \
       fi
