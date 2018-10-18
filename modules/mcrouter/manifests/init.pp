# == Class: mcrouter
#
# mcrouter is a fast routing proxy for memcached.
# It can reduce the connection count on the backend caching servers
# and also supports layered pools, replication, and key/operation
# based routing to pools.
#
# === Parameters
#
# [*pools*]
#   A hash defining a mcrouter server pool.
#   See <https://github.com/facebook/mcrouter/wiki/Config-Files>.
#
# [*routes*]
#   A list of hashes that define route handles.
#   See <https://github.com/facebook/mcrouter/wiki/List-of-Route-Handles>.
#
# [*region*]
#   Datacenter name for the one in this geographical region
#
# [*cluster*]
#   Memcached cluster name
#
# [*cross_region_timeout_ms*]
#   Timeout, in milliseconds, when performing cross-region memcached operations
#
# [*cross_cluster_timeout_ms*]
#   Timeout, in milliseconds, when performing cross-cluster memcached operations
#
# [*ssl_options*]
#   If not undef, this is a hash indicating the port to listen to for ssl and
#   the public cert, private key, and CA cert paths on the filesystem.
#
# [*num_proxies*]
#   Maximum number of connections to each backend. Defaults to 1.
#
# [*probe_delay_initial_ms*]
#   TKO probe retry initial timeout in ms. When a memcached server is marked
#   as TKO (by default after 3 timeouts registered), mcrouter waits this amount
#   of time before sending the first health checks probes (meant to verify
#   the status of memcached before sending traffic again).
#   Defaults to 3000.
#
# [*timeouts_until_tko*]
#   Number of timeouts to happen before marking a memcached server as TKO.
#   Default: undef
#
# === Examples
#
#  class { '::mcrouter':
#    pools => {
#      cluster-main' => {
#        servers => [ '10.68.23.25:11211', '10.68.23.49:11211' ]
#      }
#    },
#    routes => [ {
#      type => 'OperationSelectorRoute',
#      default_policy => 'PoolRoute|cluster-main',
#      operation_policies => {
#        set => 'AllFastestRoute|Pool|cluster-main',
#        delete => 'AllFastestRoute|Pool|cluster-main'
#      }
#    }
#  } ]
#
class mcrouter(
    Hash $pools,
    Array $routes,
    String $region,
    String $cluster,
    Integer $port,
    Integer $cross_region_timeout_ms,
    Integer $cross_cluster_timeout_ms,
    Wmflib::Ensure $ensure = present,
    Mcrouter::Ssl $ssl_options = undef,
    Integer $num_proxies = 1,
    Integer $probe_delay_initial_ms = 3000,
    Optional[Integer] $timeouts_until_tko = undef,
) {
    require_package('mcrouter')

    $config = { 'pools' => $pools, 'routes' => $routes }

    file { '/etc/mcrouter/config.json':
        ensure       => $ensure,
        content      => ordered_json($config),
        owner        => 'root',
        group        => 'root',
        mode         => '0444',
        require      => Package['mcrouter'],
        validate_cmd => "/usr/bin/mcrouter --validate-config --port ${port} --route-prefix ${region}/${cluster} --config file:%",
    }

    file { '/etc/default/mcrouter':
        ensure  => $ensure,
        content => template('mcrouter/default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['mcrouter'],
    }

    systemd::service { 'mcrouter':
        ensure   => $ensure,
        content  => "[Service]\nLimitNOFILE=64000\nUser=mcrouter\n",
        override => true,
        restart  => true,
    }

    # Logging management
    logrotate::rule { 'mcrouter':
        ensure       => present,
        file_glob    => '/var/log/mcrouter.log',
        frequency    => 'daily',
        compress     => true,
        missing_ok   => true,
        not_if_empty => true,
        rotate       => 7,
        post_rotate  => 'service rsyslog rotate >/dev/null 2>&1 || true'
    }
    rsyslog::conf { 'mcrouter':
        source   => 'puppet:///modules/mcrouter/mcrouter.rsyslog.conf',
        priority => 20,
        require  => File['/etc/logrotate.d/mcrouter'],
        before   => Service['mcrouter'],
    }
}
