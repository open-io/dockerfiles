# openio/sds-ext-swift Dockerfile

This image provides an easy way to run an OpenStack Swift gateway using an OpenIO SDS backend.
It deploys and configure OpenStack Keystone and OpenStack Swift gateway and the services needed.

## How to use this image

This container requires you to run the [OpenIO SDS Docker image] (https://hub.docker.com/r/openio/sds/). You need the IP address of this image to connect the OpenStack Swift gateway to the OpenIO SDS backend.

### Keep it simple

Start the image providing the openio/sds container IP address:

```console
docker run -ti --tty -e OIOPROXY_IPADDR=192.168.56.101 openio/openio-sds-ext-swift
```

### Using host network interface

You can start an instance using Docker host mode networking, it allows you to access the services outside your container. You cant specify the interface or the IP you want to use.

Setting the interface:

```console
docker run -ti --tty --net=host -e OIOPROXY_IPADDR=192.168.56.101 -e OPENIO_IFDEV=enp0s8 openio/openio-sds-ext-swift
```

Specifying the IP:

```console
docker run -ti --tty --net=host -e OIOPROXY_IPADDR=192.168.56.101 -e OPENIO_IPADDR=192.168.56.101 openio/openio-sds-ext-swift
```

## OpenStack Swift & AWS S3

### OpenStack Swift CLI

OpenStack Swift Client is installed inside the container. Here is a short bootstrap to test your installation.  
Full documentation is available on the OpenStack website.

Source the provided file:

```console
# . keystonerc_demo
```

View the default account informations:

```console
# swift stat
```

Create a container in your `demo` account:

```console
# swift post my_container
```

List your files containers:

```console
# swift list
```

Upload a file in a container:

```console
# swift upload my_container /etc/redhat-release
```

List your files in your container:

```console
# swift list my_container
```

### Amazon AWS S3

The AWS CLI provided in the box.  
Full Documentation is available on the AWS Documentation website.

Load the provided Swift authentication file (in the homedir) and create your S3 credentials, then save the AWS keys:

```console
# . keystonerc_demo
# keystone ec2-credentials-create
```

Configure your AWS credentials and configuration:

```console
# mkdir ~/.aws
# vi ~/.aws/credentials
[default]
aws_access_key_id=ACCESS_KEY
aws_secret_access_key=SECRET_KEY
# vi ~/.aws/config

[default]
s3 =
  max_concurrent_requests = 20
  max_queue_size = 1000
  multipart_threshold = 10GB
  multipart_chunksize = 16MB
```

Put a file in your `demo` bucket:

```console
# aws --endpoint-url http://localhost:6007 --no-verify-ssl s3 cp /etc/magic s3://demo
```

List files in your bucket:

```console
# aws --endpoint-url http://localhost:6007 --no-verify-ssl s3 ls s3://demo
```

