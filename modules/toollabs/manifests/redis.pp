# Class: toollabs::redis
#
# This role sets up a redis node for use by tool-labs
# Restricts usage of certain commands, to prevent
# people from trampling on others' keys
# Uses default amount of RAM (1G) specified by redis class
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::redis (
    $maxmemory = '12GB',
) inherits toollabs {
    include toollabs::infrastructure
    include ::redis::client::python

    $active_redis = hiera('active_redis')
    if $active_redis != $::fqdn {
        $redis_replication = {
            "${::fqdn}" => $fqdn,
        }
    } else {
        $redis_replication = undef
    }

    include labs_lvm
    labs_lvm::volume { 'redis-disk':
        mountat => '/srv',
        size    => '100%FREE',
    }

    class { '::redis::legacy':
        dir               => '/srv/redis',
        maxmemory         => $maxmemory,
        # Disable the following commands, to try to limit people from
        # Trampling on each others' keys
        rename_commands   => {
            'CONFIG'    => '',
            'FLUSHALL'  => '',
            'FLUSHDB'   => '',
            'KEYS'      => '',
            'SHUTDOWN'  => '',
            'SLAVEOF'   => '',
            'CLIENT'    => '',
            'RANDOMKEY' => '',
            'DEBUG'     => '',
            'MONITOR'   => ''
        },
        monitor           => false,
        redis_replication => $redis_replication,
        maxmemory_policy  => 'allkeys-lru',
        require           => Labs_lvm::Volume['redis-disk'],
    }

    package { 'python-virtualenv':
        ensure => latest,
    }
}
