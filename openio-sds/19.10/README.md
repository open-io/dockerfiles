# openio/sds


Build Docker image based on [ansible playbook](https://github.com/open-io/ansible-playbook-openio-deployment)


## How to get this image from the hub

To get the latest one built on the [docker hub](https://hub.docker.com/r/openio/sds) 

```shell
docker pull openio/sds
```

or

```shell
docker pull openio/sds:latest
```

## How to (re-)build this image

First get the source:

```shell
git clone https://github.com/open-io/dockerfiles.git
cd dockerfiles/openio-sds/19.10/centos/7
./build.sh
#docker tag openio/sds:19.10  openio/sds:latest
docker push openio/sds:19.10
#docker push openio/sds:latest
```
