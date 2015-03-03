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
    $maxmemory = '1GB',
    $replicate_from = undef,
) inherits toollabs {
    include toollabs::infrastructure
    include ::redis::client::python

    if $replicate_from {
        $redis_replication = {
            "${::hostname}" => $replicate_from,
        }
    } else {
        $redis_replication = undef
    }

    # LVM for redis data!
    labs_lvm::volume { 'redis-data':
        mountat => '/var/lib/redis',
    }

    class { '::redis':
        persist           => 'aof',
        dir               => '/var/lib/redis',
        maxmemory         => $maxmemory,
        # Disable the following commands, to try to limit people from
        # Trampling on each others' keys
        rename_commands => {
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
        monitor           => true,
        redis_replication => $redis_replication,
        require           => Mount['/var/lib/redis'], # Provided by labs_lvm::volume
    }

    diamond::collector { 'Redis':
        require => Class['::redis::client::python']
    }
}
