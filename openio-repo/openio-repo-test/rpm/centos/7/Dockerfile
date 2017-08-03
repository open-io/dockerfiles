FROM centos:7

RUN yum install -y epel-release

# Test installing a package from the repository
CMD curl http://172.17.0.1:8080/pub/keyFile.pub > /keyFile.pub && \
    rpm --import /keyFile.pub && \
    { \
        echo "[oio-sds]"; \
        echo "name=OpenIO SDS Packages for Centos $releasever - $basearch"; \
        echo "baseurl=http://${OIO_REPO_IP}:${OIOREPO_PORT}/${OIOREPO_PATH}/\$basearch"; \
        echo "enabled=1"; \
        echo "gpgcheck=1"; \
        echo "gpgkey=http://${OIO_REPO_IP}:${OIOREPO_PORT}/pub/keyFile.pub"; \
    } > /etc/yum.repos.d/oio-sds.repo && \
    yum install -y ${OIO_PACKAGE}
