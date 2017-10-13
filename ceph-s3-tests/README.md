# This image launches up to date ceph s3 test suite

## Build the ceph s3 test suite image

    git clone https://github.com/open-io/dockerfiles.git
    cd dockerfiles
    docker build -t ceph-s3-tests ceph-s3-tests

## Run a amazon-s3 enabled openio/sds docker container as a target for the tests

    SWIFT_CREDENTIALS="admin:admin:admin:.admin .reseller_admin,test2:tester2:testing2:.admin,test5:tester5:testing5:service,test:tester:testing:.admin,test:tester3:testing3"
    DOCKER_ID_OIOSDS=$(docker run -d --rm -e OPENIO_IFDEV=eth0 -e SWIFT_CREDENTIALS="${SWIFT_CREDENTIALS}" openio/sds:17.04)
    # Get its IP address
    DOCKER_IP_OIOSDS=$(docker inspect ${DOCKER_ID_OIOSDS} --format "{{.NetworkSettings.IPAddress}}")

## Run the test suite

    docker run -ti --rm -e "AWS_S3_HOST=${DOCKER_IP_OIOSDS}" -e "AWS_S3_PORT=6007" ceph-s3-tests
