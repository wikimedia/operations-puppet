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
# [*route*]
#   A hash defining a mcrouter routing policy.
#   See <https://github.com/facebook/mcrouter/wiki/List-of-Route-Handles>.
#
# === Examples
#
#  class { '::mcrouter':
#    pools => {
#      cluster-eqiad' => {
#        servers => [ '10.68.23.25:11211', '10.68.23.49:11211' ]
#      },
#      cluster-codfw => {
#        servers => [ '10.68.22.239:11211', '10.68.22.239:11211' ]
#      },
#    },
#    route => {
#      type => 'OperationSelectorRoute',
#      default_policy => 'PoolRoute|eqiad-cluster-1',
#      operation_policies => {
#        set => {
#          type => 'AllFastestRoute',
#          children => [ 'PoolRoute|eqiad-cluster-1', 'PoolRoute|eqiad-cluster-2' ]
#        },
#        delete => {
#          type => 'AllFastestRoute',
#          children => [ 'PoolRoute|eqiad-cluster-1', 'PoolRoute|eqiad-cluster-2' ]
#        }
#      }
#    }
#  }
#
class mcrouter(
    $pools,
    $route,
    $ensure    = present
) {
    validate_hash($pools)
    validate_hash($route)

    require_package('mcrouter')

    file { '/etc/mcrouter/mcrouter.json':
        ensure  => $ensure,
        content => template('mcrouter/mcrouter.json.erb'),
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
        File['/etc/mcrouter/mcrouter.json'] {
          validate_cmd => '/usr/sbin/mcrouter --validate-config --conf-file %',
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
    }
}
