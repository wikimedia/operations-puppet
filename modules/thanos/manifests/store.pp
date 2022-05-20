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

# TODO(filippo) evaluate using memcache (shared with swift) for caching
class thanos::store (
    Hash[String, String] $objstore_account,
    String $objstore_password,
    Stdlib::Port::Unprivileged $http_port = 11902,
    Stdlib::Port::Unprivileged $grpc_port = 11901,
    Optional[String] $min_time = undef,
    Optional[String] $max_time = undef,
    Optional[String] $consistency_delay = undef,
) {
    ensure_packages(['thanos'])

    $http_address = "0.0.0.0:${http_port}"
    $grpc_address = "0.0.0.0:${grpc_port}"
    $service_name = 'thanos-store'
    $data_dir = '/srv/thanos-store'
    $cache_config_file = '/etc/thanos-store/cache.yaml'
    $objstore_config_file = '/etc/thanos-store/objstore.yaml'

    file { $data_dir:
        ensure => directory,
        mode   => '0750',
        owner  => 'thanos',
        group  => 'thanos',
    }

    file { '/etc/thanos-store':
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }

    file { $cache_config_file:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('thanos/store_cache.yaml.erb'),
    }

    file { $objstore_config_file:
        ensure    => present,
        mode      => '0440',
        owner     => 'thanos',
        group     => 'root',
        show_diff => false,
        content   => template('thanos/objstore.yaml.erb'),
    }

    systemd::service { $service_name:
        ensure         => present,
        restart        => true,
        override       => true,
        content        => systemd_template('thanos-store'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }
}
