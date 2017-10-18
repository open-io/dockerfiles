FROM oiosds:scratch-centos7-deps
MAINTAINER "Jean-Francois Smigielski" <jf.smigielski@gmail.com>
ARG OIOREPO=https://github.com/open-io/oio-sds.git

# Attempt to download only once the sources
RUN mkdir /tmp/src \
  && cd /tmp/src \
  && git clone "$OIOREPO" \
  && cd /tmp/src/oio-sds \
  && git fetch --all

ARG COMMIT_ID=master

# Now checkout in the right commit-id, then build and install
RUN cd /tmp/src/oio-sds \
  && git checkout -b "$COMMIT_ID" "$COMMIT_ID" \
  && cmake \
    -D CMAKE_INSTALL_PREFIX=/usr \
    -D CMAKE_BUILD_TYPE=Release \
    . \
  && make -j 4 \
  && make install \
  && pip install --upgrade -r test-requirements.txt \
  && pip install --upgrade -r all-requirements.txt \
  && python ./setup.py install

EXPOSE 6000-7000

CMD ["/usr/bin/env", "bash"]

