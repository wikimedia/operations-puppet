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
    $maxmemory = '1GB'
) inherits toollabs {
    include toollabs::infrastructure

    class { '::redis':
        persist         => 'aof',
        dir             => '/var/lib/redis',
        maxmemory       => $maxmemory,
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
        monitor         => true
    }

    # Enable diamond monitoring. It needs the redis python
    # module.
    package { 'python-redis': }

    diamond::collector { 'Redis':
        require => Package['python-redis']
    }
}
