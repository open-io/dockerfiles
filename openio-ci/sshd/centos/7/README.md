# BUILD
```
docker build -t openio/centos7_sshd .
```

# RUN
```
docker run -d --cap-add SYS_ADMIN \
  --volume=/sys/fs/cgroup:/sys/fs/cgroup:ro \
  openio/centos7_sshd:latest \
  /usr/lib/systemd/systemd
```
```
# password: centos
ssh-copy-id centos@172.17.0.2
```
