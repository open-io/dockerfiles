# openio/openstack-keystone Dockerfile

This image provides an easy way to run an Openstack Keystone identity service to use along with an OpenIO SDS container.    
It deploys and configure a simple non-replicated Openstack Keystone instance in a single Docker container and configure an object-store endpoint.
This image supports Keystone API v3 (and should work with the deprecated v2.0).  

## How to use this image

You need to specify on which IP address/DNS name your identity service and object-store are running.  
The Keystone service will be listening on both port `5000` (for public access) and `35357` (for admin access). Port `5000` will be available at the end of the container configuration.  

By default, the container starts a Keystone service on localhost (127.0.0.1) inside the container.  
An `admin` user is created in the `default` domain, with an `admin` role in the `admin` project using the `ADMIN_PASS` password.  
A `demo` user is created for testing purposes, in the `default` domain, with an `admin` role in the `demo` project, using the `DEMO_PASS` password.


```console
# docker run -d openio/openstack-keystone
```

```console
# docker run -d --net=host -e IPADDR=192.168.56.102 openio/openstack-keystone
```

Using the Openstack CLI and your credentials, you can use this credentials Keystone (`OS_AUTH_URL` should be different):  
```console
export OS_IDENTITY_API_VERSION="3"
export OS_AUTH_URL="http://192.168.56.102:5000"
export OS_USER_DOMAIN_ID="default"
export OS_PROJECT_DOMAIN_ID="default"
export OS_PROJECT_NAME="admin"
export OS_USERNAME="admin"
export OS_PASSWORD="ADMIN_PASS"
```

## Documentation
