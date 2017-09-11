#!/bin/bash
set -x

### Openstack Keystone

: ${OS_RELEASE:=pike}
: ${IPADDR:=127.0.0.1}
# Identity service configuration
: ${OS_IDENTITY_URL_IPADDR:=$IPADDR}
: ${OS_IDENTITY_API_VERSION:=3}
: ${OS_IDENTITY_SERVICE_REGION:=RegionOne}
: ${OS_IDENTITY_SERVICE_NAME:=keystone}
: ${OS_IDENTITY_ADMIN_DOMAIN:=default}
: ${OS_IDENTITY_ADMIN_PROJECT:=admin}
: ${OS_IDENTITY_ADMIN_USERNAME:=admin}
: ${OS_IDENTITY_ADMIN_PASSWD:=ADMIN_PASS}
: ${OS_IDENTITY_ADMIN_ROLE:=admin}
: ${OS_IDENTITY_URL_ADMIN:=http://${IPADDR}:35357}
: ${OS_IDENTITY_URL_INTERNAL:=http://${IPADDR}:5000}
: ${OS_IDENTITY_URL_PUBLIC:=http://${IPADDR}:5000}
# Object store configuration
: ${OS_OBJECTSTORE_URL_IPADDR:=$IPADDR}
: ${OS_OBJECTSTORE_SERVICE_REGION:=RegionOne}
: ${OS_OBJECTSTORE_SERVICE_NAME:=openio-swift}
: ${OS_OBJECTSTORE_SERVICE_DESC:=OpenIO Swift Object Storage Service}
: ${OS_OBJECTSTORE_DOMAIN:=default}
: ${OS_OBJECTSTORE_PROJECT:=service}
: ${OS_OBJECTSTORE_USERNAME:=swift}
: ${OS_OBJECTSTORE_PASSWD:=SWIFT_PASS}
: ${OS_OBJECTSTORE_ROLE:=admin}
: ${OS_OBJECTSTORE_URL_ADMIN:=http://${IPADDR}:6007/v1}
: ${OS_OBJECTSTORE_URL_INTERNAL:=http://${IPADDR}:6007/v1/AUTH_%(tenant_id)s}
: ${OS_OBJECTSTORE_URL_PUBLIC:=http://${IPADDR}:6007/v1/AUTH_%(tenant_id)s}
# Demo user setup
: ${OS_USER_DEMO_DOMAIN:=default}
: ${OS_USER_DEMO_PROJECT:=demo}
: ${OS_USER_DEMO_USERNAME:=demo}
: ${OS_USER_DEMO_PASSWD:=DEMO_PASS}
: ${OS_USER_DEMO_ROLE:=admin}

echo '> Configuring Keystone ...'
# Set log to stderr for Docker
openstack-config --set /etc/keystone/keystone.conf DEFAULT use_stderr True
# Use a local sqlite database for demo purposes
openstack-config --set /etc/keystone/keystone.conf database connection 'sqlite:////var/lib/keystone/keystone.db'
keystone-manage credential_setup \
  --keystone-user keystone \
  --keystone-group keystone
keystone-manage fernet_setup \
  --keystone-user keystone \
  --keystone-group keystone
keystone-manage db_sync
keystone-manage bootstrap \
  --bootstrap-project-name "$OS_IDENTITY_ADMIN_PROJECT" \
  --bootstrap-username "$OS_IDENTITY_ADMIN_USERNAME" \
  --bootstrap-username "$OS_IDENTITY_ADMIN_USERNAME" \
  --bootstrap-password "$OS_IDENTITY_ADMIN_PASSWD" \
  --bootstrap-role-name "$OS_IDENTITY_ADMIN_ROLE" \
  --bootstrap-service-name "$OS_IDENTITY_SERVICE_NAME" \
  --bootstrap-region-id "$OS_IDENTITY_SERVICE_REGION" \
  --bootstrap-admin-url "$OS_IDENTITY_URL_ADMIN" \
  --bootstrap-public-url "$OS_IDENTITY_URL_PUBLIC" \
  --bootstrap-internal-url "$OS_IDENTITY_URL_INTERNAL"

# Using uwsgi for demo purposes
echo '> Starting Keystone admin service ...'
/usr/bin/keystone-wsgi-admin --port 35357 &


# Admin credentials
cat <<EOF >/keystone_adminrc
export OS_IDENTITY_API_VERSION="$OS_IDENTITY_API_VERSION"
#export OS_AUTH_URL="$OS_IDENTITY_URL_PUBLIC"
export OS_AUTH_URL="$OS_IDENTITY_URL_ADMIN"
export OS_USER_DOMAIN_ID="$OS_IDENTITY_ADMIN_DOMAIN"
export OS_PROJECT_DOMAIN_ID="$OS_IDENTITY_ADMIN_DOMAIN"
export OS_PROJECT_NAME="$OS_IDENTITY_ADMIN_PROJECT"
export OS_USERNAME="$OS_IDENTITY_ADMIN_USERNAME"
export OS_PASSWORD="$OS_IDENTITY_ADMIN_PASSWD"
EOF
source /keystone_adminrc

# Create roles
echo '> Creating Keystone roles ...'
openstack role create 'admin'
openstack role create 'swiftoperator'
openstack role create '_member_'
# Object store service
echo '> Registering Object Store service ...'
openstack project create "$OS_OBJECTSTORE_PROJECT"
openstack user create --password "$OS_OBJECTSTORE_PASSWD" --project "$OS_OBJECTSTORE_PROJECT" "$OS_OBJECTSTORE_USERNAME"
openstack role add --user "$OS_OBJECTSTORE_USERNAME" --project "$OS_OBJECTSTORE_PROJECT" "$OS_OBJECTSTORE_ROLE"
openstack service create --name "$OS_OBJECTSTORE_SERVICE_NAME" --description "$OS_OBJECTSTORE_SERVICE_DESC" --enable 'object-store'
openstack endpoint create --region "$OS_OBJECTSTORE_SERVICE_REGION" 'object-store' public   "$OS_OBJECTSTORE_URL_PUBLIC"
openstack endpoint create --region "$OS_OBJECTSTORE_SERVICE_REGION" 'object-store' internal "$OS_OBJECTSTORE_URL_INTERNAL"
openstack endpoint create --region "$OS_OBJECTSTORE_SERVICE_REGION" 'object-store' admin    "$OS_OBJECTSTORE_URL_ADMIN"
# Demo user
openstack domain create "$OS_USER_DEMO_DOMAIN"
openstack project create "$OS_USER_DEMO_PROJECT"
openstack user create --password "$OS_USER_DEMO_PASSWD" --project "$OS_USER_DEMO_PROJECT" "$OS_USER_DEMO_USERNAME"
openstack role add --user "$OS_USER_DEMO_USERNAME" --project "$OS_USER_DEMO_PROJECT" "$OS_USER_DEMO_ROLE"

echo '> Starting Keystone public service ...'
/usr/bin/keystone-wsgi-public --port 5000
