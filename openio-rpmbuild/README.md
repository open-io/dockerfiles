# What is openio/rpmbuild?

This image provides an easy way to build RPM packages without configuring a dedicated server.
It is built from a [Fedora](https://getfedora.org) 22 distribution, and provide a Python script that wraps the process to create a package, relying on rpmbuild and [Mock](https://fedoraproject.org/wiki/Mock) to build clean packages in chrooted environment.  
The container should run in [*privileged mode*](http://blog.docker.com/2013/09/docker-can-now-run-within-docker/).  

# How to use this image

## Build a package

To build a package, you must specify at least a RPM specfile through the SPECFILE environment variable.  

```console
# docker run -e SPECFILE=https://raw.githubusercontent.com/open-io/rpm-specfiles/master/python-oiopy/python-oiopy.spec --privileged=true --rm openio/rpmbuild
```

Default distribution is *epel-7-x86_64*, get the full list in the [Mock source](http://pkgs.fedoraproject.org/cgit/mock.git/). Specify the *DISTRIBUTION* environment variable choose another:  

```console
# docker run -e DISTRIBUTION=fedora-22-x86_64 -e SPECFILE=https://raw.githubusercontent.com/open-io/rpm-specfiles/master/python-oiopy/python-oiopy.spec --privileged=true --rm openio/rpmbuild
```


## Features

### specfile from GIT
If your specfile and your sources are versionned like in Fedora's repository, you can set the SPECFILE parameter to a [GIT](https://git-scm.com) repository. By default, it points to the *master branch*:   

```console
docker run -e DISTRIBUTION=fedora-22-x86_64 -e SPECFILE=http://pkgs.fedoraproject.org/git/bash.git --privileged=true --rm openio/rpmbuild
```

You may add URL options to point a specific *branch*:  

```console
docker run -e DISTRIBUTION=fedora-22-x86_64 -e SPECFILE=http://pkgs.fedoraproject.org/git/bash.git?branch=f22 --privileged=true --rm openio/rpmbuild
```

or *commit*:  

```console
docker run -e DISTRIBUTION=fedora-22-x86_64 -e SPECFILE=http://pkgs.fedoraproject.org/git/bash.git?commit=469c21de51421a30eb99aad8a02148043fcdccce --privileged=true --rm openio/rpmbuild
```

### Alternative sources
Like for the specfile, you can specify alternative download for your source files. It can be either simple HTTP download or a GIT repository.  

```console
docker run -e DISTRIBUTION=fedora-22-x86_64 -e SPECFILE=http://pkgs.fedoraproject.org/git/bash.git?commit=469c21de51421a30eb99aad8a02148043fcdccce SOURCES="ftp://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz" --privileged=true --rm openio/rpmbuild
```

### Use cache
This image relies on Mock that uses caches to build package faster. As you create a new container from scratch each time you want to build a package, you'd feed the cache every time you run the container.  
This image allows you to bind a local directory or another container to keep the cache fetched by Mock in `/var/cache/mock` through your packages build.  

* Using a cache container:  

```console
# docker run -ti -v /var/cache/mock --name rpmbuild-cache-container alpine true
```

```console
# docker run -e SPECFILE=https://raw.githubusercontent.com/open-io/rpm-specfiles/master/python-oiopy/python-oiopy.spec --privileged=true --rm --volumes-from rpmbuild-cache-container openio/rpmbuild
```
To access the cache:  

```console
# docker run -ti --rm --volumes-from rpmbuild-cache-container alpine sh
```

### Access the result
You might want to get your packages, the logs or the chroot at the end of the build, you can mount `/var/lib/mock` on your host to access this informations:

Create a local directory:

```console
# mkdir -pv local/lib/mock
```

```console
# docker run -e SPECFILE=https://raw.githubusercontent.com/open-io/rpm-specfiles/master/python-oiopy/python-oiopy.spec --privileged=true -v local/lib/mock:/var/lib/mock --rm openio/rpmbuild
```

### Upload resulting packages
You can upload the resulting packages using SCP:  

```console
# docker run -e UPLOAD_RESULT="scp://host/remote_path/?port=22&username=user&password=passwd" -e SPECFILE=https://raw.githubusercontent.com/open-io/rpm-specfiles/master/python-oiopy/python-oiopy.spec --privileged=true -v local/lib/mock:/var/lib/mock --rm openio/rpmbuild
```

Or you can upload using http to an oiorepo flask web application:

```console
OIO_REPO_IP=`ip -4 address show dev docker0 | awk '/inet / {print substr($2,0,index($2,"/") - 1)}'`
# docker run -e UPLOAD_RESULT="http://${OIO_REPO_IP}:5000/package" \
             -e OIO_PROD="sds" \
             -e OIO_PROD_VER="16.10" \
             -e OIO_DISTRO="centos" \
             -e OIO_DISTRO_VER="7" \
             -e OIO_ARCH="x86_64" \
             -e OIO_COMPANY="openio" \
             -e OIO_PACKAGE="python-oiopy" \
             --privileged=true \
             -v local/lib/mock:/var/lib/mock \
             --rm \
             openio/rpmbuild
```

# License

The included script is provided under [Apache License v2](http://www.apache.org/licenses/LICENSE-2.0).
