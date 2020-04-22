# openio/sds


Build Docker image based on [ansible playbook](https://github.com/open-io/ansible-playbook-openio-deployment)


## How to get this image from the hub

To get the latest one built on the [docker hub](https://hub.docker.com/r/openio/sds) 

```shell
docker pull openio/sds
```

or

```shell
docker pull openio/sds:18.04
```

## How to (re-)build this image

First get the source:

```shell
git clone https://github.com/open-io/dockerfiles.git
cd dockerfiles/openio-sds/18.04/centos/7
./build.sh
docker push openio/sds:18.04
```
