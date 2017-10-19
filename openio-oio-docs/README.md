# oio-docs

This image provides an easy way to build OpenIO documentation site.  

## How to use this image

Clone the OpenIO documentation repository:  

```console
# git clone git@github.com:open-io/oio-docs.git
```

Then build the documentation using:  

```console
# docker run -ti -v $PWD/oio-docs:/mnt openio/oio-docs
```

You can enable a simple HTTP server listening on port `3000` that serve the documentation:  

```console
# docker run -ti -e ENABLE_HTTP=yes -p 3000:3000 -v $PWD/oio-docs:/mnt docker.io/openio/oio-docs
```
