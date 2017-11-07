# Default ipaddress to use
$ipaddr = '127.0.0.1'

# Deploy a single node
class {'gridinit':
  no_exec => true,
}
class{'openiosds':}
openiosds::namespace {'OPENIO':
  ns                       => 'OPENIO',
  conscience_url           => "${ipaddr}:6000",
  oioproxy_url             => "${ipaddr}:6006",
  eventagent_url           => "beanstalk://${ipaddr}:6014",
  ecd_url                  => "${ipaddr}:6017",
  meta1_digits             => 0,
  ns_storage_policy        => 'SINGLE',
  ns_chunk_size            => '10485760',
  ns_service_update_policy => {
    'meta2' => 'KEEP|1|1|',
    'sqlx'  => 'KEEP|1|1|',
    'rdir'  => 'KEEP|1|1|user_is_a_service=rawx'},
}
openiosds::oioswift {'oioswift-0':
  ns               => 'OPENIO',
  ipaddress        => '0.0.0.0',
  sds_proxy_url    => "http://${ipaddr}:6006",
  auth_system      => 'keystone',
  username         => "%SWIFT_USERNAME%",
  password         => "%SWIFT_PASSWORD%",
  auth_uri         => "http://%KEYSTONE_URI%",
  auth_url         => "http://%KEYSTONE_URL%",
  memcache_servers => "${ipaddr}:6019",
  region_name      => "%REGION%",
  middleware_swift3 => {'location' => '%REGION%'},
  no_exec          => true,
}
