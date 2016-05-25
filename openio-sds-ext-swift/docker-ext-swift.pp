$ipaddr = 'OPENIO_IPADDR'
$oioproxy_ipaddr = 'OIOPROXY_IPADDR'

### Install and configure Keystone
#class { 'keystone':
#  verbose             => True,
#  admin_token         => 'KEYSTONE_ADMIN_UUID',
#  database_connection => 'sqlite:////var/lib/keystone/keystone.db',
#  manage_service      => false,
#  paste_config        => '/etc/keystone/keystone-paste.ini',
#  enable_bootstrap    => True,
#}

# Adds the admin credential to Keystone.
class { 'keystone::roles::admin':
  email        => 'test@openio.io',
  password     => 'ADMIN_PASS',
}

# Installs the Keystone service user endpoints.
class { 'keystone::endpoint':
  public_url   => "http://${ipaddr}:5000",
  admin_url    => "http://127.0.0.1:5000",
  internal_url => "http://127.0.0.1:35357",
  region       => 'localhost-1',
}

# Configure the Swift service into Keystone
keystone_user { 'swift':
  ensure  => present,
  enabled => True,
  password => 'SWIFT_PASS',
}
keystone_user_role { 'swift@services':
  roles  => ['admin'],
  ensure => present
}
keystone_service { 'openio-swift':
  ensure      => present,
  type        => 'object-store',
  description => 'OpenIO SDS swift proxy',
}
keystone_endpoint { 'localhost-1/openio-swift':
   ensure       => present,
   type         => 'object-store',
   public_url   => "http://${ipaddr}:6007/v1.0/AUTH_%(tenant_id)s",
   admin_url    => "http://${ipaddress}:6007/v1.0/AUTH_%(tenant_id)s",
   internal_url => "http://${ipaddress}:6007/v1.0/AUTH_%(tenant_id)s",
}

# Configure the `demo@demo` tenant and account into Keystone
keystone_tenant { 'demo':
  ensure  => present,
  enabled => True,
}
keystone_user { 'demo':
  ensure  => present,
  enabled => True,
  password => "DEMO_PASS",
}
keystone_role { '_member_':
  ensure => present,
}
keystone_user_role { 'demo@demo':
  roles  => ['admin','_member_'],
  ensure => present
}

# Install and configure the OpenIO Swift gateway
class {'openiosds':}
openiosds::namespace {'OPENIO':
  ns => 'OPENIO',
}
openiosds::oioswift {'oioswift-1':
  num           => '1',
  ns            => 'OPENIO',
  ipaddress     => '0.0.0.0',
  sds_proxy_url => "http://${oioproxy_ipaddr}:6006",
  no_exec       => true,
}
