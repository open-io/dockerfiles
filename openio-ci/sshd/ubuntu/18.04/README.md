# BUILD
```
docker build -t openio/ubuntu18.04_sshd .
```

# RUN
```
docker run -d \
  --volume=/run \
  --volume=/run/lock \
  --volume=/tmp \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
  --cap-add=SYS_ADMIN \
  openio/ubuntu18.04_sshd:latest /sbin/init
```
```
# password: ubuntu
ssh-copy-id centos@172.17.0.2
```
