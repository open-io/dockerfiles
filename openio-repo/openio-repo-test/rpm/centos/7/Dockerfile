FROM centos:7

RUN yum install -y epel-release

# Test installing a package from the repository

CMD rpm --import http://${OIO_REPO_IP}:${OIO_REPO_PORT}/pub/repo/openio/RPM-GPG-KEY-OPENIO-0 && \
    { \
        echo "[oio-sds]"; \
        echo "name=OpenIO SDS Packages for Centos $releasever - $basearch"; \
        echo "baseurl=http://${OIO_REPO_IP}:${OIO_REPO_PORT}/${OIO_REPO_PATH}/\$basearch"; \
        echo "enabled=1"; \
        echo "gpgcheck=1"; \
        echo "gpgkey=http://${OIO_REPO_IP}:${OIO_REPO_PORT}/pub/repo/openio/RPM-GPG-KEY-OPENIO-0"; \
    } > /etc/yum.repos.d/oio-sds.repo && \
    yum install -y ${OIO_PACKAGE}
