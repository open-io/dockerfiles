# cosbench-openio

This image provides an easy way to run [COSbench](https://github.com/intel-cloud/cosbench) with the [OpenIO SDS](http://www.openio.io) backend support.

## How to use this image

By default, COSbench starts as a controller and a driver to allow you to start
a bench.

Environment variables available are:  
- `DRIVER`: Starts as a COSbench driver (Default to `true`)
- `CONTROLLER`: Starts as a COSbench controller (Default to `true`)
- `DRIVERS`: Comma separated list of COSbench drivers to be used by the controller
 (Default to `http://127.0.0.1:18088/driver`)
- `COSBENCH_PLUGINS`: Comma separated list of COSbench OSGI plugins to load. The more you add, the slower it is to start (Default to `OPENIO`. Available values: `OPENIO,CDMI,SWIFT,SCALITY,S3,CEPH,AMPLI`)


Start a simple COSbench container:  
```console
# docker run --net=host -ti --tty racciari/cosbench-openio
```
Then you can access the COSbench Web Interface through `http://localhost:19088/controller/index.html`

## Define COSbench Workloads

- Using the OpenIO SDS Java API
You need to start your controller with the `OPENIO` support.
* Authentication
 * Type: `None`
* Storage
 * Type: `openio`
 * Configuration: `ns=<NAMESPACE>;account=<ACCOUNT>;proxyd-url=<OIOPROXY_URL>;ecd-url=<ECD_URL>`

- Using the Openstack Swift API with Keystone:
You need to start your controller with the `SWIFT` support.
 * Authentication
  * Type: `keystone`
  * Configuration: `username=<USERNAME>;password=<PASSWORD>;tenant_name=<TENANT>;auth_url=http://<KEYSTONE_URL>/v2.0;service=<SWIFT_SERVICE>`
 * Storage
  * Type: `swift`
  * Configuration: `storage_url=http://<SWIFT_PROXY_URL>/auth/v1.0`

- Using the AWS S3 API:
You need to start your controller with the `S3` support.
 * Authentication
  * Type: `None`
 * Storage
  * Type: `s3`
  * Configuration: `accesskey=<accesskey>;secretkey=<scretkey>;proxyhost=<proxyhost>;proxyport=<proxyport>;endpoint=<endpoint>`
