# BUILD
```
docker build -t openio/centos8_ansible:2.9 -f Dockerfile_2.9 .
```

# RUN
```
docker run -d \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cap-add=SYS_ADMIN \
  openio/centos8_ansible:2.9 /usr/lib/systemd/systemd
```

