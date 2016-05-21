### Install and configure Keystone
class { 'keystone':
  verbose             => True,
  admin_token         => 'KEYSTONE_ADMIN_UUID',
  database_connection => 'sqlite:////var/lib/keystone/keystone.db',
  manage_service      => false,
  paste_config        => '/etc/keystone/keystone-paste.ini',
  enable_bootstrap    => True,
}
