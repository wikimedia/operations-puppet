# SPDX-License-Identifier: Apache-2.0
# == Class: profile::thanos::query_frontend
#
# Configure the Thanos query-frontend component.
# Memcached is supported, and shared with Swift (frontend)

class profile::thanos::query_frontend (
    Array[Stdlib::Host] $memcached_hosts = lookup('profile::thanos::query_frontend::memcached_hosts'),
) {
    $http_port = 16902

    class { 'thanos::query_frontend':
        http_port       => $http_port,
        memcached_hosts => $memcached_hosts,
        memcached_port  => 11211,
    }
}
