# Use an official Python runtime as a base image
FROM python:3-slim

# Install repository creation tools for RPM & DEB packaging formats
RUN set -ex && apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        createrepo dpkg-dev apt-utils && \
    rm -rf /var/lib/apt/lists/*

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Install python packages
RUN mkdir -p /oiorepodestdir /oio-repo
COPY setup.py /oio-repo
COPY openiorepo /oio-repo/openiorepo
RUN pip install /oio-repo && rm -rf /oio-repo

COPY doit.sh /

# Run FLASK_APP when the container launches, listening to all networks
CMD ["/doit.sh"]
