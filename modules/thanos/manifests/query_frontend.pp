# SPDX-License-Identifier: Apache-2.0
# == Class: thanos::query_frontend
#
# The thanos query-frontend command implements a service that can be put in front of Thanos Queriers
# to improve the read path. It is based on the Cortex Query Frontend component so you can find some
# common features like Splitting and Results Caching.
#
# Query Frontend is fully stateless and horizontally scalable.
#
# = Parameters
# [*http_port*] The port to listen on for HTTP
# [*downstream_url*] The url to talk to for queries
# [*log_queries_longer_than*] Log queries taking longer than the specified duration
# [*max_query_length*] Reject queries requesting a range longer than this duration (h/m/s)
# [*memcached_hosts*] List of hostnames for memcached caching, empty list disables memcached
# [*memcached_port*] The port for memcached client

class thanos::query_frontend (
    Stdlib::Port::Unprivileged $http_port = 16902,
    String $downstream_url = 'http://localhost:10902',
    Pattern[/\d+[hms]/] $log_queries_longer_than = '20s',
    Pattern[/\d+[hms]/] $max_query_length = '0s',
    Array[Stdlib::Host] $memcached_hosts = [],
    Stdlib::Port $memcached_port = 11211,
    Boolean $request_debug = false,
) {
    ensure_packages(['thanos'])

    $http_address = "0.0.0.0:${http_port}"
    $service_name = 'thanos-query-frontend'
    $cache_config_file = '/etc/thanos-query-frontend/cache.yaml'

    file { '/etc/thanos-query-frontend':
        ensure => directory,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
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
          'addresses'     => $memcached_hosts.map |$h| { "${h}:${memcached_port}" },
          'timeout'       => '3s',
          'max_item_size' => '1MB',
          'max_async_concurrency' => 20, # Required default to have memcached writes work
          'max_async_buffer_size' => 10000, # Default will be included in Thanos itself, required for now
          'dns_provider_update_interval' => '60s', # https://github.com/thanos-io/thanos/issues/3324
        }
      }
    }

    file { '/usr/local/bin/thanos-query-log-explore':
        ensure => present,
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/thanos/query-log-explore.py',
    }

    file { $cache_config_file:
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => to_yaml($cache_config),
        notify  => Service[$service_name],
    }

    $logging_config = @("CONFIG")
        http:
          options:
            level: DEBUG
            decision:
              log_start: true
              log_end: true
        | CONFIG

    file { '/etc/thanos-query-frontend/request-logging.yaml':
        ensure  => present,
        content => $logging_config,
    }

    $logging_cmdline = $request_debug ? {
        true    => '--log.level=debug --request.logging-config-file=/etc/thanos-query-frontend/request-logging.yaml',
        default => '',
    }

    systemd::service { $service_name:
        ensure         => present,
        restart        => true,
        override       => true,
        content        => systemd_template('thanos-query-frontend'),
        service_params => {
            enable     => true,
            hasrestart => true,
        },
    }
}
