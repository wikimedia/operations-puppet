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
#        delete => 'AllSyncRoute|Pool|cluster-main'
#      }
#    }
#  } ]
#
class mcrouter(
    $pools,
    $routes,
    $region,
    $cluster,
    $port,
    $cross_region_timeout_ms,
    $cross_cluster_timeout_ms,
    $ensure    = present
) {
    validate_hash($pools)
    validate_array($routes)

    require_package('mcrouter')

    $config = { 'pools' => $pools, 'routes' => $routes }

    file { '/etc/mcrouter/config.json':
        ensure  => $ensure,
        content => ordered_json($config),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        require => Package['mcrouter'],
    }

    if (
        $ensure == 'present' and
        versioncmp($::puppetversion, '3.5') >= 0 and
        versioncmp($::serverversion, '3.5') >= 0
        ) {
        File['/etc/mcrouter/config.json'] {
          validate_cmd => "/usr/bin/mcrouter --validate-config --port ${port} --route-prefix ${region}/${cluster} --config file:%",
        }
    }

    file { '/etc/default/mcrouter':
        ensure  => $ensure,
        content => template('mcrouter/default.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['mcrouter'],
    }

    file { '/etc/init/mcrouter.override':
        ensure  => $ensure,
        content => "limit nofile 64000 64000\n",
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service['mcrouter'],
    }

    service { 'mcrouter':
        ensure => ensure_service($ensure),
        enable => $ensure ? {
            'present' => true,
            default   => false
        }
    }
}
