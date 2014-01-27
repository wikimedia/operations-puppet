class openstack::swift::proxy (
  $swift_admin_tenant               = 'services',
  $swift_admin_user                 = 'swift',
  $swift_user_password              = 'swift_pass',
  $swift_hash_suffix                = 'swift_secret',
  $swift_local_net_ip               = $::ipaddress_eth0,
  $swift_proxy_net_ip               = $::ipaddress_eth0,
  $ring_part_power                  = 18,
  $ring_replicas                    = 3,
  $ring_min_part_hours              = 1,
  $proxy_pipeline                   = ['catch_errors', 'healthcheck', 'cache', 'ratelimit', 'swift3', 's3token', 'authtoken', 'keystone', 'proxy-server'],
  $proxy_workers                    = $::processorcount,
  $proxy_port                       = '8080',
  $proxy_allow_account_management   = true,
  $proxy_account_autocreate         = true,
  $ratelimit_clock_accuracy         = 1000,
  $ratelimit_max_sleep_time_seconds = 60,
  $ratelimit_log_sleep_time_seconds = 0,
  $ratelimit_rate_buffer_seconds    = 5,
  $ratelimit_account_ratelimit      = 0,
  $package_ensure                   = 'present',
  $controller_node_address          = '10.0.0.1',
  $keystone_host                    = '10.0.0.1',
  $memcached                        = true,
  $swift_memcache_servers           = ['127.0.0.1:11211'],
  $memcached_listen_ip              = '127.0.0.1'
) {

  if $controller_node_address !='10.0.0.1' {
    warning('The param controller_node_address has been deprecated, use keystone_host instead')
    $real_keystone_host = $controller_node_address
  } else {
    $real_keystone_host = $keystone_host
  }
  class { 'swift':
    swift_hash_suffix => $swift_hash_suffix,
    package_ensure    => $package_ensure,
  }

  if $memcached {
    class { 'memcached':
      listen_ip => $memcached_listen_ip,
    }
  }

  class { '::swift::proxy':
    proxy_local_net_ip       => $swift_proxy_net_ip,
    pipeline                 => $proxy_pipeline,
    port                     => $proxy_port,
    workers                  => $proxy_workers,
    allow_account_management => $proxy_allow_account_management,
    account_autocreate       => $proxy_account_autocreate,
    package_ensure           => $package_ensure,
    require                  => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class { [
    '::swift::proxy::catch_errors',
    '::swift::proxy::healthcheck',
    '::swift::proxy::swift3',
  ]: }

  class { 'swift::proxy::cache':
    memcache_servers => $swift_memcache_servers,
  }

  class { '::swift::proxy::ratelimit':
    clock_accuracy         => $ratelimit_clock_accuracy,
    max_sleep_time_seconds => $ratelimit_max_sleep_time_seconds,
    log_sleep_time_seconds => $ratelimit_log_sleep_time_seconds,
    rate_buffer_seconds    => $ratelimit_rate_buffer_seconds,
    account_ratelimit      => $ratelimit_account_ratelimit,
  }

  class { '::swift::proxy::s3token':
    auth_host     => $real_keystone_host,
    auth_port     => '35357',
  }
  class { '::swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }
  class { '::swift::proxy::authtoken':
    admin_user        => $swift_admin_user,
    admin_tenant_name => $swift_admin_tenant,
    admin_password    => $swift_user_password,
    auth_host         => $real_keystone_host,
  }

  # collect all of the resources that are needed
  # to balance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  # create the ring
  class { 'swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
    part_power     => $ring_part_power,
    replicas       => $ring_replicas,
    min_part_hours => $ring_min_part_hours,
    require        => Class['swift'],
  }

  # sets up an rsync db that can be used to sync the ring DB
  class { 'swift::ringserver':
    local_net_ip => $swift_local_net_ip,
  }

  # deploy a script that can be used for testing
  class {'swift::test_file':
    auth_server  => $real_keystone_host,
    tenant       => $swift_admin_tenant,
    user         => $swift_admin_user,
    password     => $swift_user_password,
  }
}
