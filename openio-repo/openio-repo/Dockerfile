# Use an official Python runtime as a base image
FROM python:3-slim

# Install repository creation tools for RPM & DEB packaging formats
RUN set -ex && apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        createrepo dpkg-dev apt-utils && \
    rm -rf /var/lib/apt/lists/*

# Add GPG private key file
COPY test/keyFile /

# Import the keys into the store
RUN gpg --import /keyFile && rm -rf /keyFile

RUN mkdir /oio-repo
#WORKDIR /oio-repo

# Install python packages
COPY setup.py /oio-repo
COPY openio-repo /oio-repo/openio-repo
RUN pip install /oio-repo && rm -rf /oio-repo

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable
ENV FLASK_APP oiorepo

# Run FLASK_APP when the container launches, listening to all networks
CMD ["flask", "run", "--host=0.0.0.0"]
