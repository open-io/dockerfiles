# Use an official Python runtime as a base image
FROM python:3-slim

# Install repository creation tools for RPM & DEB packaging formats
RUN set -ex && apt-get update && apt-get upgrade -y && apt-get install -y createrepo dpkg-dev apt-utils --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Add GPG private key file
COPY test/keyFile /

# Import the keys into the store
RUN gpg --import /keyFile && rm -rf /keyFile

# Set the working directory to /oio-repo
WORKDIR /oio-repo

# Install python packages
COPY setup.py openio-repo .
RUN pip install . && rm -rf openio-repo setup.py

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Define environment variable
ENV FLASK_APP oiorepo

# Run FLASK_APP when the container launches, listening to all networks
CMD ["flask", "run", "--host=0.0.0.0"]
