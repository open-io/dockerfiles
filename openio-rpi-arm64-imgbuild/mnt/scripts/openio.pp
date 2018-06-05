class {'openiosds':}
openiosds::namespace {'OPENIO':
  ns                       => 'OPENIO',
  conscience_url           => "${ipaddr}:6000",
  oioproxy_url             => "${ipaddr}:6006",
  eventagent_url           => "beanstalk://${ipaddr}:6014",
  ns_service_update_policy => {'meta2'=>'KEEP|1|1|','sqlx'=>'KEEP|1|1|','rdir'=>'KEEP|1|1|user_is_a_service=rawx'},
  ns_storage_policy        => 'SINGLE',
  meta1_digits   => 0,
}
openiosds::account {'account-0':
  ns         => 'OPENIO',
  ipaddress  => '$ipaddr',
  redis_host => '$ipaddr',
}
openiosds::conscience {'conscience-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
openiosds::meta0 {'meta0-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
openiosds::meta1 {'meta1-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
openiosds::meta2 {'meta2-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
openiosds::rawx {'rawx-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
openiosds::rdir {'rdir-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
  location  => "${hostname}-other",
}
openiosds::oioblobindexer {'oio-blob-indexer-rawx-0':
  ns        => 'OPENIO',
}
openiosds::oioeventagent {'oio-event-agent-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
openiosds::oioproxy {'oioproxy-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
openiosds::redis {'redis-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
openiosds::conscienceagent {'conscienceagent-0':
  ns        => 'OPENIO',
}
openiosds::beanstalkd {'beanstalkd-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
openiosds::oioswift {'oioswift-0':
  ns               => 'OPENIO',
  ipaddress        => '0.0.0.0',
  sds_proxy_url    => "http://${ipaddr}:6006",
  auth_system      => 'tempauth',
  tempauth_users   => ['demo:demo:DEMO_PASS:.admin'],
  memcache_servers => "${ipaddr}:6019",
}
openiosds::memcached {'memcached-0':
  ns        => 'OPENIO',
  ipaddress => '$ipaddr',
}
