# To sign the repositories

The GPG signing keys for the test repositories have been generated like that: 

    cd test
    gpg --quick-generate-key --batch --passphrase '' test@test.com
    gpg --armor --output keyFile.pub --export 845C305473F3DB14D8CF3DA0135F9FDEDDB25AA8
    gpg --armor --output keyFile --export-secret-keys 845C305473F3DB14D8CF3DA0135F9FDEDDB25AA8

# Docker

- official docker python images are based on debian stable
- debian docker images have official distro packages for:
  * dpkg-dev, apt-utils
  * createrepo

# To build the openio-repo service docker images

    docker build -t openio-repo -f Dockerfile .

# To run the openio-repo container

- With local TCP port 5000 mapping to be accessible from outside
- With local directory (/tmp/oio-repo) mounted inside the container (at /tmp) to
  keep repo storage outside docker

    docker run -p 5000:5000 -v /tmp/oio-repo:/tmp openio-repo

# To run as a daemon (a docker stack in a docker swarm)

    docker swarm init
    docker stack deploy -c docker-compose.yml openio-repo-stack

# To stop the stack

    docker stack rm openio-repo-stack
    docker swarm leave --force

# To serve the repository files through HTTP (on port 8000)

    # Start a HTTP server for yum to download the files from
    cd /tmp/oio-repo
    python -m SimpleHTTPServer

# To browse the repositories

    firefox http://localhost:8000/openio/sds/16.10

# To test the openio-repo container

    # Upload a RPM package, will trigger the repository creation
    curl -F 'file=@test/rpm/centos/7/openio-sds-tools-3.2.3-1.el7.oio.x86_64.rpm' \
         -F 'company=openio' \
         -F 'prod=sds' \
         -F 'prod_ver=16.10' \
         -F 'distro=centos' \
         -F 'distro_ver=7' \
         -F 'arch=x86_64' \
         http://127.0.0.1:5000/package

    # Upload a DEB package, will trigger the repository creation
    curl -F 'file=@test/deb/debian/jessie/openio-sds_3.2.3-2_amd64.deb' \
         -F 'company=openio' \
         -F 'prod=sds' \
         -F 'prod_ver=16.10' \
         -F 'distro=debian' \
         -F 'distro_ver=jessie' \
         -F 'arch=amd64' \
         http://127.0.0.1:5000/package

Note the arch difference between RPM & DEB repositories, when in fact it's the
same.

Refresh the opened page in firefox to see the just added package

# To populate a complete CentOS 7 repository

    cd test/rpm/centos/7
    wget -r -l 1 http://mirror.openio.io/pub/repo/openio/sds/16.10/centos/7/x86_64
    for f in mirror.openio.io/pub/repo/openio/sds/16.10/centos/7/x86_64/*.rpm ; do
        curl -F "file=@$f" \
             -F 'company=openio' \
             -F 'prod=sds' \
             -F 'prod_ver=16.10' \
             -F 'distro=centos' \
             -F 'distro_ver=7' \
             -F 'arch=x86_64' \
             http://127.0.0.1:5000/package
    done

# To populate a complete Debian jessie repository

    cd test/deb/debian/jessie
    wget -r -l 1 http://mirror.openio.io/pub/repo/openio/sds/16.10/debian/jessie
    for f in mirror.openio.io/pub/repo/openio/sds/16.10/debian/jessie/*.deb ; do
        curl -F "file=@$f" \
             -F 'company=openio' \
             -F 'prod=sds' \
             -F 'prod_ver=16.10' \
             -F 'distro=debian' \
             -F 'distro_ver=jessie' \
             -F 'arch=amd64' \
             http://127.0.0.1:5000/package
    done

# To populate a complete Ubuntu xenial repository

    cd test/deb/ubuntu/xenial
    wget -r -l 1 http://mirror.openio.io/pub/repo/openio/sds/16.10/ubuntu/xenial
    for f in mirror.openio.io/pub/repo/openio/sds/16.10/ubuntu/xenial/*.deb ; do
        curl -F "file=@$f" \
             -F 'company=openio' \
             -F 'prod=sds' \
             -F 'prod_ver=16.10' \
             -F 'distro=ubuntu' \
             -F 'distro_ver=xenial' \
             -F 'arch=amd64' \
             http://127.0.0.1:5000/package
    done

# To build the openio-repo-test-* docker images

    DOCKER_HOST_IP=`ip -4 address show dev docker0 | awk '/inet / {print substr($2,0,index($2,"/") - 1)}'`
    docker build --build-arg DOCKER_HOST_IP=${DOCKER_HOST_IP} -t openio-repo-test-centos7 test/rpm/centos/7
    docker build --build-arg DOCKER_HOST_IP=${DOCKER_HOST_IP} -t openio-repo-test-debianjessie test/deb/debian/jessie
    docker build --build-arg DOCKER_HOST_IP=${DOCKER_HOST_IP} -t openio-repo-test-ubuntuxenial test/deb/ubuntu/xenial

# To test the new repositories automatically

    # Run a CentOS 7 container with the new repository ready
    docker run -ti openio-repo-test-centos7

    # Run a Debian jessie + backports container with the new repository ready
    docker run -ti openio-repo-test-debianjessie

    # Run an Ubuntu xenial container with the new repository ready
    docker run -ti openio-repo-test-ubuntuxenial

# To test the new repositories manually

    # Run a CentOS 7 container with the new repository ready
    docker run -ti openio-repo-test-centos7 /bin/bash
    # In that container's bash shell
    yum install openio-sds-tools

    # Run a Debian jessie container with the new repository ready
    docker run -ti openio-repo-test-debianjessie /bin/bash
    # In that container's bash shell
    apt update
    apt install openio-sds

    # Run a Ubuntu xenial container with the new repository ready
    docker run -ti openio-repo-test-ubuntuxenial /bin/bash
    # In that container's bash shell
    apt update
    apt install openio-sds

# Debian repositories

- https://wiki.debian.org/DebianRepository/Format

# Redhat repositories

- http://createrepo.baseurl.org
- http://yum.baseurl.org/wiki/RepoCreate
