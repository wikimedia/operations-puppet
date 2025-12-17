# SPDX-License-Identifier: Apache-2.0
# == Class: thanos::store
#
# The thanos store command (also known as Store Gateway) implements the Store
# API on top of historical data in an object storage bucket. It keeps a small
# amount of information about all remote blocks on local disk and keeps it in
# sync with the bucket.
#
# = Parameters
# [*objstore_account*] The account to use to access object storage
# [*objstore_password*] The password to access object storage
# [*http_port*] The port to use for HTTP
# [*grpc_port*] The port to use for gRPC
# [*min_time*] Start of time range limit to serve. Can be RFC3339-style
#              absolute time or relative to now (e.g. -1d)
# [*max_time*] End of time range limit to serve. Can be RFC3339-style
#              absolute time or relative to now (e.g. -1d)
# [*consistency_delay*] Minimum age of all blocks before they are being read.
# [*memlimit_ratio*] Set GOMEMLIMIT to system/container memory * ratio. Use 0.0 to disable.
# [*tracing_enabled*] Self explanatory
# [*memcached_hosts*] List of hostnames for memcached caching, empty list disables memcached
# [*memcached_port*] The port for memcached client
# [*limits_request_series*] The maximum series allowed for a single Series request. 0 to disable.
# [*limits_request_samples*] The maximum samples allowed for a single Series request. 0 to disable.
# [*query_hosts*] Querier(s)

define thanos::store (
    Hash[String, String] $objstore_account,
    String $objstore_password,
    Stdlib::Port::Unprivileged $http_port = 11902,
    Stdlib::Port::Unprivileged $grpc_port = 11901,
    Optional[String] $min_time = undef,
    Optional[String] $max_time = undef,
    Optional[String] $consistency_delay = undef,
    Float[0, 1] $memlimit_ratio = 0.7,
    Boolean $tracing_enabled = false,
    Array[Stdlib::Host] $memcached_hosts = [],
    Stdlib::Port $memcached_port = 11211,
    Integer[0] $limits_request_series = 0,
    Integer[0] $limits_request_samples = 0,
    Optional[Thanos::Store::RelabelRules] $block_selector = undef,
    Array $query_hosts = [],
) {
    ensure_packages(['thanos'])

    $http_address = "0.0.0.0:${http_port}"
    $grpc_address = "0.0.0.0:${grpc_port}"
    $service_name = "thanos-store@${title}"
    $config_dir = "/etc/thanos-store@${title}"
    $cache_config_file = "${config_dir}/cache.yaml"
    $objstore_config_file = "${config_dir}/objstore.yaml"
    $tracing_config_file = "${config_dir}/tracing-config.yml"
    $selector_relabel_config_file = "${config_dir}/selector-relabel-config.yaml"
    $data_dir = "/srv/thanos-store@${title}"

    file { $config_dir:
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $data_dir:
        ensure => directory,
        mode   => '0750',
        owner  => 'thanos',
        group  => 'thanos',
    }

    if empty($memcached_hosts) {
      $cache_config = {
        'type'   => 'IN-MEMORY',
        'config' => {
          'max_size'      => '16GB',
          'max_item_size' => '30MB',
        }
      }
    } else {
      $cache_config = {
        'type'   => 'MEMCACHED',
        'config' => {
          'addresses' => $memcached_hosts.map |$h| { "${h}:${memcached_port}" },
        }
      }
    }

    file { $cache_config_file:
        ensure  => present,
        mode    => '0444',
        content => to_yaml($cache_config),
        notify  => Service[$service_name],
    }

    file { $objstore_config_file:
        ensure    => present,
        mode      => '0440',
        owner     => 'thanos',
        group     => 'root',
        show_diff => false,
        content   => template('thanos/objstore.yaml.erb'),
    }

    file { $selector_relabel_config_file:
        ensure  => present,
        mode    => '0444',
        content => to_yaml($block_selector),
        notify  => Service[$service_name],
    }

    thanos::tracing { $tracing_config_file:
        service_name => $service_name,
        sampler_type => 'parentbasedalwayssample',
        notify       => Service[$service_name],
    }

    systemd::service { $service_name:
        ensure         => present,
        restart        => true,
        content        => systemd_template('thanos-store@'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }

    # Allow access from query hosts
    $query_hosts_ferm = join($query_hosts, ' ')
    ferm::service { "thanos_store_query_${title}":
        proto  => 'tcp',
        port   => $grpc_port,
        srange => "(@resolve((${query_hosts_ferm})) @resolve((${query_hosts_ferm}), AAAA))",
    }
}
