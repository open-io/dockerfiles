


# BUILD
```
docker build -t openio/ubuntu18.04_ansible:2.9 -f Dockerfile_2.9 .
```

# RUN
```
docker run -d \
  --volume=/run \
  --volume=/run/lock \
  --volume=/tmp \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cap-add=SYS_ADMIN \
  openio/ubuntu18.04_ansible:2.9 /sbin/init
```

